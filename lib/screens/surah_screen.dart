import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../models/reciter.dart';
import '../services/quran_service.dart';
import '../widgets/verse_card.dart';

class SurahScreen extends StatefulWidget {
  final Surah surah;
  final Reciter reciter;

  const SurahScreen({
    super.key,
    required this.surah,
    required this.reciter,
  });

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  final QuranService _quranService = QuranService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Verse>? _verses;
  int? _currentVerseIndex;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadVerses();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _audioPlayer.positionStream.listen((position) {
      // Auto-advance verse based on position could be implemented here
    });
  }

  Future<void> _loadVerses() async {
    final verses = await _quranService.getVerses(widget.surah.number);
    setState(() {
      _verses = verses;
    });
  }

  Future<void> _playVerse(int index) async {
    if (_currentVerseIndex == index && _isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    final audioUrl = _quranService.getAudioUrl(widget.reciter, widget.surah.number);

    try {
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
      setState(() {
        _currentVerseIndex = index;
        _isPlaying = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F1A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.surah.name,
                style: GoogleFonts.amiri(
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.teal.withOpacity(0.3),
                      const Color(0xFF0F0F1A),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        widget.surah.englishName,
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.surah.numberOfAyahs} verses',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
          if (_verses == null)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.teal,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final verse = _verses![index];
                  return VerseCard(
                    verse: verse,
                    surah: widget.surah,
                    isPlaying: _isPlaying,
                    isCurrentVerse: _currentVerseIndex == index,
                    onPlay: () => _playVerse(index),
                  );
                },
                childCount: _verses?.length ?? 0,
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      bottomNavigationBar: _buildAudioControls(),
    );
  }

  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            StreamBuilder<Duration?>(
              stream: _audioPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = _audioPlayer.duration ?? Duration.zero;
                final progress = duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0.0;

                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rewind
                IconButton(
                  onPressed: () async {
                    final newPosition = _audioPlayer.position -
                        const Duration(seconds: 10);
                    await _audioPlayer.seek(
                      newPosition > Duration.zero ? newPosition : Duration.zero,
                    );
                  },
                  icon: const Icon(Icons.replay_10),
                  color: Colors.white70,
                  iconSize: 28,
                ),
                const SizedBox(width: 16),
                // Play/Pause
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (_currentVerseIndex != null) {
                        _playVerse(_currentVerseIndex!);
                      } else if (_verses != null && _verses!.isNotEmpty) {
                        _playVerse(0);
                      }
                    },
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    color: Colors.white,
                    iconSize: 32,
                  ),
                ),
                const SizedBox(width: 16),
                // Forward
                IconButton(
                  onPressed: () async {
                    final duration = _audioPlayer.duration ?? Duration.zero;
                    final newPosition = _audioPlayer.position +
                        const Duration(seconds: 10);
                    await _audioPlayer.seek(
                      newPosition < duration ? newPosition : duration,
                    );
                  },
                  icon: const Icon(Icons.forward_10),
                  color: Colors.white70,
                  iconSize: 28,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.reciter.name,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
