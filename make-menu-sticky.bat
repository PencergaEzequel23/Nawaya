

@echo off
setlocal
set "NAWAYA_PATCH=%~f0"

powershell.exe -NoProfile -Command "$text=[IO.File]::ReadAllText($env:NAWAYA_PATCH);$parts=[regex]::Split($text,'(?m)^# BEGIN_POWERSHELL\r?$');if($parts.Length -ne 2){throw 'Could not read the updater.'};& ([scriptblock]::Create($parts[1]))"

set "RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %RESULT%

# BEGIN_POWERSHELL
$ErrorActionPreference = "Stop"

try {
    $folder = Split-Path -LiteralPath $env:NAWAYA_PATCH
    $cssPath = Join-Path $folder "menu.css"
    $jsPath = Join-Path $folder "menu.js"

    if (!(Test-Path -LiteralPath $cssPath)) {
        throw "menu.css was not found. Put this updater in your website folder."
    }

    if (!(Test-Path -LiteralPath $jsPath)) {
        throw "menu.js was not found. Put this updater in your website folder."
    }

    $css = [IO.File]::ReadAllText($cssPath)
    $js = [IO.File]::ReadAllText($jsPath)

    $oldLine = 'start + target.getBoundingClientRect().top - 24,'

    $newLine = 'start + target.getBoundingClientRect().top - (target.id === "menu-categories" ? 0 : document.querySelector("#menu-categories").getBoundingClientRect().height + 16),'

    if ($js.Contains($oldLine)) {
        $js = $js.Replace($oldLine, $newLine)
    }
    elseif (
        !$js.Contains($newLine) -and
        !$js.Contains("const stickyOffset")
    ) {
        throw "Your menu.js differs from the version I provided. Nothing was changed. Send me your current menu.js so I can update it safely."
    }

    $marker = "/* Nawaya sticky category bar */"

    if (!$css.Contains($marker)) {
        $css += @"

/* Nawaya sticky category bar */
.menu-categories {
  position: sticky;
  top: 0;
  z-index: 100;
  background: #141311;
  box-shadow: 0 4px 12px rgb(0 0 0 / 18%);
}
"@
    }

    $cssBackup = "$cssPath.before-sticky.bak"
    $jsBackup = "$jsPath.before-sticky.bak"

    if (!(Test-Path -LiteralPath $cssBackup)) {
        Copy-Item -LiteralPath $cssPath -Destination $cssBackup
    }

    if (!(Test-Path -LiteralPath $jsBackup)) {
        Copy-Item -LiteralPath $jsPath -Destination $jsBackup
    }

    $encoding = [System.Text.UTF8Encoding]::new($false)

    [IO.File]::WriteAllText($cssPath, $css, $encoding)
    [IO.File]::WriteAllText($jsPath, $js, $encoding)

    Write-Host ""
    Write-Host "DONE! Your menu category bar is now sticky." -ForegroundColor Green
    Write-Host "Category scrolling has also been updated."
    Write-Host "Original versions were backed up."
    Write-Host ""
    Write-Host "Refresh your website with Ctrl + F5."
}
catch {
    Write-Host ""
    Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
