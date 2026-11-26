

@echo off
setlocal
cd /d "%~dp0"

where curl.exe >nul 2>&1
if errorlevel 1 (
  echo ERROR: curl.exe was not found.
  pause
  exit /b 1
)

if not exist "assets\news" mkdir "assets\news"

if not exist "assets\news" (
  echo ERROR: Could not create the image folder.
  pause
  exit /b 1
)

call :download "https://www.figma.com/api/mcp/asset/478b600e-9c2a-46d2-b8a2-53e4a158bdd0.png" "news-1.png"
call :download "https://www.figma.com/api/mcp/asset/be7b75ae-0fb2-4325-ada7-6a2efd359b48.png" "news-2.png"
call :download "https://www.figma.com/api/mcp/asset/29285e5a-3a69-4d26-9686-d76c9d90971c.png" "news-3.png"

echo.
if defined failed (
  echo Some downloads failed.
  echo A 403 or 404 error may mean a temporary link expired.
) else (
  echo Done! All three news images downloaded.
)

explorer "%~dp0assets\news"
pause
exit /b

:download
echo Downloading %~2...

curl.exe -fL --retry 2 --connect-timeout 20 --max-time 120 "%~1" -o "assets\news\%~2.part"

if errorlevel 1 (
  echo FAILED: %~2
  set "failed=1"
  if exist "assets\news\%~2.part" del /q "assets\news\%~2.part"
) else (
  move /y "assets\news\%~2.part" "assets\news\%~2" >nul
  if errorlevel 1 (
    echo FAILED TO SAVE: %~2
    set "failed=1"
  )
)

exit /b
