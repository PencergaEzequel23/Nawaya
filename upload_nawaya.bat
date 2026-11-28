@echo off
cd /d "C:\Users\leuqe\Desktop\nawaya2"

echo ========================================================
echo Two-Way Sync: PC ^<--^> GitHub (Nawaya)
echo ========================================================

echo [1/5] Fixing SSL connection and buffer limits...
git config --global http.sslBackend schannel
git config --global http.postBuffer 524288000
git config user.name "PencergaEzequel23"
git config user.email "PencergaEzequel23@gmail.com"

echo [2/5] Verifying GitHub remote link...
git branch -M main
git remote remove origin 2>nul
git remote add origin https://github.com/PencergaEzequel23/Nawaya.git

echo [3/5] Saving local PC changes...
git add .
git commit -m "Sync Nawaya project"

echo [4/5] Pulling changes from GitHub to PC...
git pull origin main --no-edit

echo [5/5] Uploading merged changes to GitHub...
git push -u origin main

echo ========================================================
echo Finished! Refresh https://github.com/PencergaEzequel23/Nawaya
echo Live site: https://pencergaezequel23.github.io/Nawaya/
echo ========================================================
pause