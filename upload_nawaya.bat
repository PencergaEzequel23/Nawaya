
@echo off
cd /d "C:\Users\leuqe\Desktop\nawaya2"

git config --global user.name "PencergaEzequel23"
git config --global user.email "PencergaEzequel23@gmail.com"

cd /d "C:\Users\leuqe\Desktop\nawaya2"
git add .
git commit -m "Initial commit"
git branch -M main
git remote remove origin 2>nul
git remote add origin https://github.com/PencergaEzequel23/Nawaya.git
git push -u origin main


echo.
echo Done! Check the output above for any errors.
pause