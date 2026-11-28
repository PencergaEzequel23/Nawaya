@echo off
setlocal
pushd "%~dp0.."
if errorlevel 1 exit /b 1
copy /Y "%~dp0index.html" "index.html" >nul
copy /Y "%~dp0menu.html" "menu.html" >nul
if exist "nwc-fixed.css" del /q "nwc-fixed.css"
if exist "nwc-fixed.js" del /q "nwc-fixed.js"
popd
echo Restored. Refresh with Ctrl+F5.
pause