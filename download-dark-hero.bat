

@echo off
setlocal
cd /d "%~dp0"

if not exist "assets\stores" mkdir "assets\stores"

echo Downloading the darker store hero...

curl.exe -fL --retry 2 "https://www.figma.com/api/mcp/asset/4d17328f-cdef-4005-91d6-7517b95b54c6.png" -o "assets\stores\store-banner.png.part"

if errorlevel 1 (
  echo.
  echo Download failed. The temporary link may have expired.
  if exist "assets\stores\store-banner.png.part" del /q "assets\stores\store-banner.png.part"
  pause
  exit /b 1
)

move /y "assets\stores\store-banner.png.part" "assets\stores\store-banner.png" >nul

if errorlevel 1 (
  echo Could not save the image.
  pause
  exit /b 1
)

echo.
echo Done! The darker hero image has been saved.
pause
