@echo off
echo ===================================================
echo   MEIWA PORTAL AUTO-DEPLOY TO MEIWA.MY.ID
echo ===================================================
echo.
echo 1. Commit and push to main repo (meiwatv)...
git add portal/ .gitignore
git commit -m "update portal landing page"
git push origin main

echo.
echo 2. Deploying portal to online repository (meiwatv-portal)...
git subtree split --prefix=portal -b temp-portal-deploy
git push portal-repo temp-portal-deploy:main --force
git branch -D temp-portal-deploy

echo.
echo ===================================================
echo   BERHASIL! Website http://meiwa.my.id/ terupdate.
echo   (Jika tampilan belum berubah di browser, tekan Ctrl+F5)
echo ===================================================
pause
