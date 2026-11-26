@echo off
cd /d "%~dp0"

if not exist "assets" mkdir "assets"

echo Downloading images...
echo.

curl.exe -fL "https://www.figma.com/api/mcp/asset/a4ad8e0f-a8e7-4d43-b74a-dee65e3b0d88" -o "assets\hero-background.jpg"
if errorlevel 1 goto failed

curl.exe -fL "https://www.figma.com/api/mcp/asset/6bc4d263-0b90-448f-90f8-65b3dc618119" -o "assets\hero-coffee.png"
if errorlevel 1 goto failed

curl.exe -fL "https://www.figma.com/api/mcp/asset/755c2211-5ec8-4cff-b02f-de042eeddba6.png" -o "assets\spanish.png"
if errorlevel 1 goto failed

curl.exe -fL "https://www.figma.com/api/mcp/asset/d518772b-e535-4a57-8658-bb3a75d8f80f.png" -o "assets\sunset.png"
if errorlevel 1 goto failed

curl.exe -fL "https://www.figma.com/api/mcp/asset/64f5c29c-31bf-45e2-b315-b9c42b968a10.png" -o "assets\moonlight.png"
if errorlevel 1 goto failed

curl.exe -fL "https://www.figma.com/api/mcp/asset/0bdaf898-77ea-49e0-a24d-0a7dc7e54075.png" -o "assets\store-map.png"
if errorlevel 1 goto failed

curl.exe -fL "https://www.figma.com/api/mcp/asset/f7e79c63-7fb5-44b8-a5d1-62d026686bd9.png" -o "assets\coffee-beans.png"
if errorlevel 1 goto failed

curl.exe -fL "https://www.figma.com/api/mcp/asset/359306ba-867e-407d-b5da-9acd0d818439.png" -o "assets\fresh-coffee.png"
if errorlevel 1 goto failed

curl.exe -fL "https://www.figma.com/api/mcp/asset/605eb882-5803-44da-9fba-15660c63a29f.png" -o "assets\espresso.png"
if errorlevel 1 goto failed

echo.
echo Done! All 9 images are inside the assets folder.
explorer "%~dp0assets"
pause
exit /b 0

:failed
echo.
echo A download failed. Check the error above.
echo If it says 403 or 404, the temporary link may have expired.
pause
exit /b 1
