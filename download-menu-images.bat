

@echo off
setlocal
cd /d "%~dp0"

where curl.exe >nul 2>&1
if errorlevel 1 (
  echo ERROR: curl.exe was not found.
  pause
  exit /b 1
)

if not exist "assets\menu" mkdir "assets\menu"

if not exist "assets\menu" (
  echo ERROR: Could not create assets\menu.
  pause
  exit /b 1
)

echo Downloading menu images...
echo Keep this window open.
echo.

rem Hero
call :download "https://www.figma.com/api/mcp/asset/b2b1b9b1-fd47-4707-a0df-32d84102a8a6.png" "menu-hero.png"

rem Signatures
call :download "https://www.figma.com/api/mcp/asset/2534b1a0-2342-4019-b804-15a749faf208.png" "sunset.png"
call :download "https://www.figma.com/api/mcp/asset/cbc175fd-92c0-4dd0-8fba-f8d473d02c36.png" "moonlight.png"
call :download "https://www.figma.com/api/mcp/asset/9a0f0ee8-8a3b-4869-bf4c-5bd3a14656b1.png" "dreamy.png"
call :download "https://www.figma.com/api/mcp/asset/1f103a8b-f735-496b-ade0-02b2a964e365.png" "spanish.png"

rem Iced coffee
call :download "https://www.figma.com/api/mcp/asset/29d274ef-b74c-4173-b195-8a7a4f172e34.png" "cloudy.png"
call :download "https://www.figma.com/api/mcp/asset/627f330d-fc1d-4171-a813-8e3c7a7031ee.png" "pumpkin.png"
call :download "https://www.figma.com/api/mcp/asset/f53e4423-0cfd-4b92-8529-fa2676834d62.png" "biscoff.png"
call :download "https://www.figma.com/api/mcp/asset/98dcda57-9548-4073-a6b7-8c4547548397.png" "americano.png"

rem Non-coffee
call :download "https://www.figma.com/api/mcp/asset/5dbe1fa0-2a85-4a3d-b4ba-823b0faa7557.png" "strawberry-milk.png"
call :download "https://www.figma.com/api/mcp/asset/4b809ad0-7593-44e8-abd5-54fae62bd1ab.png" "matcha.png"
call :download "https://www.figma.com/api/mcp/asset/4eeffa90-c0ce-4b92-a7f2-27ccff2e408a.png" "oreo.png"
call :download "https://www.figma.com/api/mcp/asset/0ba1280c-1759-4ef4-8532-045220ef46f2.png" "matcha-berry.png"
call :download "https://www.figma.com/api/mcp/asset/eb0b2d70-785e-4d4b-bc1d-381c5c0ff881.png" "mango.png"
call :download "https://www.figma.com/api/mcp/asset/3ee92cab-6714-45ee-a28a-c8cb4ed3d736.png" "berry-blue.png"

rem Fruit soda
call :download "https://www.figma.com/api/mcp/asset/0ba06eed-1f32-4e2f-b78c-112d3a327787.png" "lychee.png"
call :download "https://www.figma.com/api/mcp/asset/a8e167e9-02aa-4bed-81f5-977d6946b5f2.png" "apple.png"
call :download "https://www.figma.com/api/mcp/asset/50e469cf-96a6-41de-8aee-1dfb0e2ca830.png" "strawberry-soda.png"
call :download "https://www.figma.com/api/mcp/asset/203f7604-e21d-4e03-a4d6-85764ac0e959.png" "blueberry.png"

rem Takoyaki
call :download "https://www.figma.com/api/mcp/asset/6cafe832-49cb-41d6-91ba-dc9c362b4d61.png" "cheese.png"
call :download "https://www.figma.com/api/mcp/asset/347110c0-4bdb-471d-bdfa-0e911f3463fc.png" "crabstick.png"
call :download "https://www.figma.com/api/mcp/asset/52548816-1e30-4f69-b51b-d0a0d2649d5d.png" "ham-veggies.png"
call :download "https://www.figma.com/api/mcp/asset/4e0648ef-3bac-4663-aca3-110823aac0bb.png" "ham-cheese.png"
call :download "https://www.figma.com/api/mcp/asset/0cdf2029-7956-4309-916b-88e1ec658926.png" "crabstick-veggies.png"

rem Carousel assets
call :download "https://www.figma.com/api/mcp/asset/63566909-e522-4d81-92d1-7142a3c9b700" "arrow-left.png"
call :download "https://www.figma.com/api/mcp/asset/1b3d6c40-f3f2-4609-9da1-a45382bc10d2" "arrow-right.png"
call :download "https://www.figma.com/api/mcp/asset/4db2517a-3016-48f8-bbbf-8730be4be5fb" "drink-shadow.png"
call :download "https://www.figma.com/api/mcp/asset/fbaca02a-653e-4cf0-aec8-d29131f4eafd" "featured-symbol-1.png"
call :download "https://www.figma.com/api/mcp/asset/ae73a466-4ea3-42f4-af05-c7a89424ab6c" "featured-symbol-2.png"

rem Product overlay symbols
call :download "https://www.figma.com/api/mcp/asset/d3af822a-0af5-45d4-9dfb-31a42b6c1eaa" "drink-symbol-1.png"
call :download "https://www.figma.com/api/mcp/asset/218a976e-9290-485f-af56-88b57bf116c9" "drink-symbol-2.png"
call :download "https://www.figma.com/api/mcp/asset/c7cd2980-b97e-47e7-92a1-556fe58f62b1" "food-symbol-1.png"
call :download "https://www.figma.com/api/mcp/asset/a96d92ab-5fb3-4266-96a3-6d761ee96795" "food-symbol-2.png"

rem Social icons
call :download "https://www.figma.com/api/mcp/asset/fba68f91-0898-442e-a20b-5f89febd2971" "facebook.png"
call :download "https://www.figma.com/api/mcp/asset/25460dce-d251-4c18-ad2a-e6ff1a94306d" "tiktok.png"
call :download "https://www.figma.com/api/mcp/asset/3787922e-e2f1-4ba1-9b57-b7340f6176a7" "instagram.png"

echo.
if defined failed (
  echo Some downloads failed. Check the messages above.
  echo A 403 or 404 error may mean a temporary link expired.
) else (
  echo SUCCESS! All 36 menu assets downloaded.
  echo Open menu.html to view the page.
)

explorer "%~dp0assets\menu"
pause
exit /b

:download
echo Downloading %~2...

curl.exe -fL --retry 2 --connect-timeout 20 --max-time 120 "%~1" -o "assets\menu\%~2.part"

if errorlevel 1 (
  echo FAILED: %~2
  set "failed=1"
  if exist "assets\menu\%~2.part" del /q "assets\menu\%~2.part"
) else (
  move /y "assets\menu\%~2.part" "assets\menu\%~2" >nul
  if errorlevel 1 (
    echo FAILED TO SAVE: %~2
    set "failed=1"
  )
)

exit /b
