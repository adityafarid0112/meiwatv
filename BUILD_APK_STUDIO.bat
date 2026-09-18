@echo off
title Build MeiwaStudio APK Release
echo ========================================================
echo   MEMULAI BUILD APK MEIWASTUDIO (RELEASE)
echo ========================================================
cd /d "%~dp0meiwastudio_app"
call flutter build apk --release
echo.
echo ========================================================
echo   BUILD SELESAI!
echo   File APK berada di:
echo   meiwastudio_app\build\app\outputs\flutter-apk\app-release.apk
echo ========================================================
pause
