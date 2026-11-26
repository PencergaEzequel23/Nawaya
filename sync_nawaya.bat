@echo off
cd /d "C:\Users\leuqe\Desktop\nawaya2"

echo [1/4] Saving your local PC changes...
git add .
git commit -m "Update Nawaya project"

echo [2/4] Downloading any new changes from GitHub (Pull)...
git pull origin main --rebase

echo [3/4] Uploading your updated code to GitHub (Push)...
git push -u origin main

echo.
echo ========================================================
echo Sync complete! PC and GitHub are now up to date.
echo ========================================================
pause