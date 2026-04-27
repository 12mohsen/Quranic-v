/* Quran PWA Service Worker */
const VERSION = 'v1.0.7';
const STATIC_CACHE    = `quran-static-${VERSION}`;
const RUNTIME_CACHE   = `quran-runtime-${VERSION}`;
const AUDIO_CACHE     = `quran-audio-${VERSION}`;
// User-initiated downloads — STABLE name (preserved across SW updates)
const DOWNLOADS_CACHE = 'quran-downloads-v1';

// Files to precache on install (app shell + local data)
const PRECACHE_URLS = [
  './',
  './index.html',
  './manifest.json',
  './icon.svg',
  './quran-simple.sql',
  './Quran .txt',
  // CDN assets (best-effort; failures are ignored individually)
  'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css',
  'https://fonts.googleapis.com/css2?family=Amiri:wght@400;700&display=swap'
];

// ---------- INSTALL ----------
self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(STATIC_CACHE);
    // Cache each url individually so one failing URL won't break install
    await Promise.all(PRECACHE_URLS.map(async (url) => {
      try {
        const req = new Request(url, { cache: 'reload' });
        const res = await fetch(req);
        if (res && (res.ok || res.type === 'opaque')) {
          await cache.put(url, res);
        }
      } catch (e) { /* ignore */ }
    }));
    // Do NOT auto-skipWaiting: let the page prompt the user
  })());
});

// ---------- ACTIVATE ----------
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.map((k) => {
      if (![STATIC_CACHE, RUNTIME_CACHE, AUDIO_CACHE, DOWNLOADS_CACHE].includes(k)) {
        return caches.delete(k);
      }
    }));
    await self.clients.claim();
  })());
});

// ---------- MESSAGE (for update flow) ----------
self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING' || event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

// ---------- FETCH ----------
self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);

  // Navigation requests -> serve index.html offline
  if (req.mode === 'navigate') {
    event.respondWith(networkFirstPage(req));
    return;
  }

  // Audio (mp3) -> check user downloads first, then on-demand cache, then network
  if (/\.(mp3|ogg|m4a|aac|wav)(\?|$)/i.test(url.pathname)) {
    event.respondWith(audioStrategy(req));
    return;
  }

  // Known API endpoints -> network-first (fresh data when online, cached when offline)
  if (
    url.hostname === 'api.alquran.cloud' ||
    url.hostname === 'www.mp3quran.net' ||
    url.hostname === 'mp3quran.net'
  ) {
    event.respondWith(networkFirst(req, RUNTIME_CACHE));
    return;
  }

  // Google Fonts / Font Awesome / other CDN assets -> stale-while-revalidate
  if (
    url.hostname === 'fonts.googleapis.com' ||
    url.hostname === 'fonts.gstatic.com' ||
    url.hostname === 'cdnjs.cloudflare.com'
  ) {
    event.respondWith(staleWhileRevalidate(req, RUNTIME_CACHE));
    return;
  }

  // Same-origin assets -> cache-first, fall back to network
  if (url.origin === self.location.origin) {
    event.respondWith(cacheFirst(req, STATIC_CACHE));
    return;
  }

  // Default: stale-while-revalidate
  event.respondWith(staleWhileRevalidate(req, RUNTIME_CACHE));
});

// ---------- STRATEGIES ----------
async function audioStrategy(req) {
  // 1) Look in user-downloads cache (preserved across versions)
  const dlCache = await caches.open(DOWNLOADS_CACHE);
  let cached = await dlCache.match(req, { ignoreSearch: true, ignoreVary: true });
  // 2) Look in transient audio cache
  if (!cached) {
    const audioCache = await caches.open(AUDIO_CACHE);
    cached = await audioCache.match(req, { ignoreSearch: true, ignoreVary: true });
  }
  if (cached) {
    // <audio> elements ALWAYS issue HTTP Range requests. If we hand back a plain
    // 200 response, several browsers (esp. Safari and some Chromium versions
    // when offline) refuse to play the media. So we always answer Range
    // requests with a proper 206 Partial Content response.
    const range = req.headers.get('range');
    if (range) return rangeFromCached(cached, range);
    return cached;
  }
  // 3) Network — and cache opportunistically (range requests skipped)
  const audioCache = await caches.open(AUDIO_CACHE);
  try {
    const res = await fetch(req);
    const isRange = req.headers.has('range');
    if (!isRange && res && (res.status === 200 || res.type === 'opaque')) {
      audioCache.put(req, res.clone()).catch(() => {});
    }
    return res;
  } catch (err) {
    // last resort — try downloads with looser match
    const fallback = await dlCache.match(req.url, { ignoreSearch: true });
    if (fallback) {
      const range = req.headers.get('range');
      if (range) return rangeFromCached(fallback, range);
      return fallback;
    }
    throw err;
  }
}

// Build a 206 Partial Content response from a cached full-body Response.
// - For the common `Range: bytes=0-` case we STREAM the cached body straight
//   through (zero buffering, ~constant memory).
// - For seek requests `Range: bytes=N-` or `bytes=N-M` we have to materialize
//   the cached body into an ArrayBuffer once to slice it. That's unavoidable
//   when the source is a Cache Storage entry (no random access on streams).
async function rangeFromCached(cachedResp, rangeHeader) {
  // Opaque responses (no-cors fallback downloads) cannot be inspected. Best we
  // can do is hand them back as-is; the browser may still play from start.
  if (cachedResp.type === 'opaque') return cachedResp;

  const ctype = cachedResp.headers.get('content-type') || 'audio/mpeg';
  const clen  = +cachedResp.headers.get('content-length') || 0;

  const m = /bytes=(\d*)-(\d*)/i.exec(rangeHeader || '');
  let start = 0, end = clen ? clen - 1 : -1;
  if (m) {
    if (m[1] !== '') start = parseInt(m[1], 10);
    if (m[2] !== '') end   = parseInt(m[2], 10);
  }

  // Fast path: full-file range and we know the size → stream the body out.
  if (start === 0 && clen && end === clen - 1) {
    return new Response(cachedResp.body, {
      status: 206,
      statusText: 'Partial Content',
      headers: {
        'Content-Type':  ctype,
        'Content-Length': String(clen),
        'Content-Range': `bytes 0-${clen - 1}/${clen}`,
        'Accept-Ranges': 'bytes',
        'Cache-Control': 'no-store'
      }
    });
  }

  // Slow path (seek): need the bytes in memory to slice. We read once.
  const buf = await cachedResp.arrayBuffer();
  const total = buf.byteLength;
  if (start < 0) start = 0;
  if (end < 0 || end >= total) end = total - 1;
  if (start > end) start = 0;
  const slice = buf.slice(start, end + 1);
  return new Response(slice, {
    status: 206,
    statusText: 'Partial Content',
    headers: {
      'Content-Type':   ctype,
      'Content-Length': String(slice.byteLength),
      'Content-Range':  `bytes ${start}-${end}/${total}`,
      'Accept-Ranges':  'bytes',
      'Cache-Control':  'no-store'
    }
  });
}

async function cacheFirst(req, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(req, { ignoreSearch: false });
  if (cached) return cached;
  try {
    const res = await fetch(req);
    if (res && (res.ok || res.type === 'opaque')) {
      cache.put(req, res.clone()).catch(() => {});
    }
    return res;
  } catch (err) {
    const fallback = await cache.match(req, { ignoreSearch: true });
    if (fallback) return fallback;
    throw err;
  }
}

async function networkFirst(req, cacheName) {
  const cache = await caches.open(cacheName);
  try {
    const res = await fetch(req);
    if (res && res.ok) cache.put(req, res.clone()).catch(() => {});
    return res;
  } catch (err) {
    const cached = await cache.match(req);
    if (cached) return cached;
    throw err;
  }
}

async function networkFirstPage(req) {
  try {
    const res = await fetch(req);
    const cache = await caches.open(STATIC_CACHE);
    cache.put('./index.html', res.clone()).catch(() => {});
    return res;
  } catch (err) {
    const cache = await caches.open(STATIC_CACHE);
    return (await cache.match('./index.html')) ||
           (await cache.match('index.html')) ||
           Response.error();
  }
}

async function staleWhileRevalidate(req, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(req);
  const fetchPromise = fetch(req).then((res) => {
    if (res && (res.ok || res.type === 'opaque')) {
      cache.put(req, res.clone()).catch(() => {});
    }
    return res;
  }).catch(() => null);
  return cached || (await fetchPromise) || Response.error();
}
