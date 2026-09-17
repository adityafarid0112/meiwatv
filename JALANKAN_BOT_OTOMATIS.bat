@echo off
title SportStream Auto-Poster Bot (Auto Update Loop)
cls
echo ====================================================
echo  SPORTSTREAM BOT - AUTO UPDATE DARI XOILACZ.VIP
echo ====================================================
echo.
echo Mode: Loop Otomatis (Akan update jadwal & stream setiap 15 menit)
echo Target: https://xoilacz.vip/
echo.
echo [INFO] Biarkan jendela terminal ini tetap terbuka agar bot
echo        dapat terus memperbarui postingan dan link live streaming.
echo.
echo ====================================================
echo.
node auto-poster.js --loop --interval 15
pause
