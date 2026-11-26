

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
  echo ERROR: Could not create the assets\news folder.
  pause
  exit /b 1
)

echo Downloading news section images...
echo.

call :download "https://www.figma.com/api/mcp/asset/1701d7f7-5cbb-4cd4-99c3-48ab7795fd9c.png" "news-hero.png"

call :download "https://www.figma.com/api/mcp/asset/1d8aff1c-d4ed-48b3-87f4-def41b71d6f5.png" "news-1.png"

call :download "https://www.figma.com/api/mcp/asset/7527f366-de85-4e4b-9c58-e30cf2ec588c.png" "news-2.png"

call :download "https://www.figma.com/api/mcp/asset/2a9bcabc-bc2f-475e-94f0-3f5b16459309.png" "news-3.png"

echo.
if defined failed (
  echo Some downloads failed.
  echo A 403 or 404 error may mean a temporary link expired.
) else (
  echo Done! All four news images downloaded.
  echo Open news.html to view the overview page.
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
