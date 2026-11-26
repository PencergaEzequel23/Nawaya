@echo off
setlocal
cd /d "%~dp0"

where curl.exe >nul 2>&1
if errorlevel 1 (
  echo ERROR: curl.exe was not found on this computer.
  pause
  exit /b 1
)

if not exist "assets\stores" mkdir "assets\stores"

if not exist "assets\stores" (
  echo ERROR: Could not create the assets\stores folder.
  pause
  exit /b 1
)

echo Downloading store-page images...
echo Please keep this window open.
echo.

rem ==========================================
rem Images used by stores.html and stores.css
rem ==========================================

call :download "https://www.figma.com/api/mcp/asset/46650d9e-742a-4d76-91ec-50721b13c315" "store-banner.png"

rem Villasis
call :download "https://www.figma.com/api/mcp/asset/ce5842ee-836d-472d-979b-fc7ff609adfd" "store-01.png"

rem Cuyapo
call :download "https://www.figma.com/api/mcp/asset/109834d8-d5c6-4d74-bffa-6c3eb0d7e241" "store-02.png"

rem Lucena
call :download "https://www.figma.com/api/mcp/asset/1244964d-3745-4e4a-a747-cc40f0c581e8" "store-03.png"

rem San Vicente
call :download "https://www.figma.com/api/mcp/asset/6793dfe7-655c-4920-b9b6-7f7907cf4bb0" "store-04.png"

rem Rosales
call :download "https://www.figma.com/api/mcp/asset/e5b892ac-b3c2-4cc6-a17a-a7789132ce82" "store-05.png"

rem Urdaneta
call :download "https://www.figma.com/api/mcp/asset/63104055-7cf0-409c-8181-08641b9c622b" "store-06.png"

rem Acop
call :download "https://www.figma.com/api/mcp/asset/46db1030-9602-48a4-a49a-6d0032711cd6" "store-07.png"

rem Tondaligan
call :download "https://www.figma.com/api/mcp/asset/23b7775c-6bef-4ef9-9428-0abee17cc4be" "store-08.png"

rem Bulangao
call :download "https://www.figma.com/api/mcp/asset/73ea0205-196a-41a9-a1f8-31d3d29c34c3" "store-09.png"

rem Complete map with pins - used by stores.html
call :download "https://www.figma.com/api/mcp/asset/8a8feac8-6885-4ea0-96ae-92185e924296.png" "store-map.png"

rem ==========================================
rem Additional separate map and icon assets
rem ==========================================

call :download "https://www.figma.com/api/mcp/asset/4c135938-3b91-4a6a-a424-93145165f39f" "map-transparent.png"

call :download "https://www.figma.com/api/mcp/asset/464e6cca-6998-41e3-95c3-685a62723c52" "map-original.png"

call :download "https://www.figma.com/api/mcp/asset/b05ec0de-e273-4b41-8087-7cfbffb31a31" "map-pin.png"

call :download "https://www.figma.com/api/mcp/asset/225e196c-f1f2-48e6-ada6-811969466196" "store-info-icon-01.png"

call :download "https://www.figma.com/api/mcp/asset/2da2d261-aea9-4f71-9515-eaae902f2316" "store-info-icon-02.png"

call :download "https://www.figma.com/api/mcp/asset/a0e72bd6-9b24-4d85-a1d0-bf48c48ea1fb" "social-icon-01.png"

call :download "https://www.figma.com/api/mcp/asset/e6065111-8300-4b6f-b227-e1e9f6b4c379" "social-icon-02.png"

call :download "https://www.figma.com/api/mcp/asset/9a12d61a-e3c9-4721-86df-0b63508dd664" "social-icon-03.png"

echo.
if defined failed (
  echo Some images could not be downloaded.
  echo Check the errors above.
  echo A 403 or 404 error may mean the download link expired.
) else (
  echo SUCCESS! All 19 images have been downloaded.
  echo Open stores.html to view your page.
)

explorer "%~dp0assets\stores"
pause
exit /b

:download
echo.
echo Downloading %~2...

curl.exe -fL --retry 2 --connect-timeout 20 --max-time 120 "%~1" -o "assets\stores\%~2.part"

if errorlevel 1 (
  echo FAILED: %~2
  set "failed=1"
  if exist "assets\stores\%~2.part" del /q "assets\stores\%~2.part"
) else (
  move /y "assets\stores\%~2.part" "assets\stores\%~2" >nul
  if errorlevel 1 (
    echo FAILED TO SAVE: %~2
    set "failed=1"
  )
)

exit /b
