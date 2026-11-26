@echo off
cd /d "C:\Users\leuqe\Desktop\nawaya2"

echo [1/4] Fixing SSL connection and buffer limits...
git config --global http.sslBackend openssl
git config --global http.postBuffer 524288000
git config --global http.version HTTP/1.1

echo [2/4] Setting up GitHub remote link...
git branch -M main
git remote set-url origin https://github.com/PencergaEzequel23/Nawaya.git || git remote add origin https://github.com/PencergaEzequel23/Nawaya.git

echo [3/4] Staging any new changes...
git add .
git commit -m "Push project files"

echo [4/4] Uploading to GitHub...
git push -u origin main

echo.
echo ========================================================
echo Finished! Refresh https://github.com/PencergaEzequel23/Nawaya
echo ========================================================
pause