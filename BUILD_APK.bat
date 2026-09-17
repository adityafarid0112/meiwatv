@echo off
title MeiwaTV - Build APK Android (Mobile, Tablet, Android TV)
cls
echo ==========================================================
echo   MEIWATV - BUILD RELEASE APK (MOBILE, TABLET, ANDROID TV)
echo ==========================================================
echo.
echo Sedang mengompilasi APK Android...
echo.
cd /d "%~dp0meiwatv_app"
call flutter build apk --release
echo.
echo ==========================================================
echo APK Berhasil Dibuat di folder:
echo meiwatv_app\build\app\outputs\flutter-apk\app-release.apk
echo ==========================================================
echo.
pause
