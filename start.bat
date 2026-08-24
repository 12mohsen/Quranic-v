@echo off
chcp 65001 >nul
title القرآن الكريم - Server
echo.
echo ══════════════════════════════════════
echo   جاري تشغيل تطبيق القرآن الكريم...
echo ══════════════════════════════════════
echo.
echo   افتح المتصفح على: http://localhost:8080/
echo   لتثبيت التطبيق: اضغط أيقونة التثبيت في شريط العنوان
echo   أو زر «تثبيت» الذي يظهر أسفل الصفحة.
echo.

:: Open the app in the default browser (index.html is the app entry point)
start "" "http://localhost:8080/index.html"

:: Try Python launcher, then python, then Node.js
py -3 -m http.server 8080 2>nul && goto :end
python -m http.server 8080 2>nul && goto :end
npx -y serve -l 8080 --no-clipboard 2>nul && goto :end

echo.
echo ❌ لم يتم العثور على Python أو Node.js
echo.
echo الحل: ثبّت Python من الرابط التالي:
echo https://www.python.org/downloads/
echo.
echo أو ثبّت Node.js من:
echo https://nodejs.org/
echo.
pause

:end
