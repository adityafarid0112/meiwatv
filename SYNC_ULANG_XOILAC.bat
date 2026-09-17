@echo off
title Sinkronisasi Xoilac Live Stream
cls
echo ====================================================
echo  SINKRONISASI JADWAL & STREAM XOILACZ.VIP -> BLOGGER
echo ====================================================
echo.
echo Membersihkan link usang dan menarik pertandingan live terbaru dari xoilacz.vip...
echo.
node clean-and-sync.js
echo.
echo Selesai. Silakan refresh blog Anda. Tekan sembarang tombol untuk keluar...
pause > nul
