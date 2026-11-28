@echo off
setlocal
set "NW_REPAIR=%~f0"

powershell.exe -NoLogo -NoProfile -Command "try { $s=[IO.File]::ReadAllText($env:NW_REPAIR); $p=$s -split '(?m)^:REPAIR_START\r?$',2; & ([scriptblock]::Create($p[1])) } catch { Write-Host $_ -ForegroundColor Red; exit 1 }"

if errorlevel 1 (
    echo.
    pause
    exit /b 1
)

call "%~dp0install-navbar-reviews.bat"
exit /b %ERRORLEVEL%

:REPAIR_START
$ErrorActionPreference = 'Stop'

try {
    $folder = [IO.Path]::GetDirectoryName($env:NW_REPAIR)
    $target = Join-Path $folder 'install-navbar-reviews.bat'

    if (!(Test-Path -LiteralPath $target -PathType Leaf)) {
        throw 'Put this repair beside install-navbar-reviews.bat.'
    }

    $encoding = [System.Text.UTF8Encoding]::new($false, $true)
    $original = [IO.File]::ReadAllText($target, $encoding)

    $corrected = [regex]::Replace(
        $original,
        '(?i)\$home\b',
        '$homepageHtml'
    )

    if ($corrected -ceq $original) {
        Write-Host 'Variable name already corrected. Starting installer.'
        exit 0
    }

    $suffix = [guid]::NewGuid().ToString('N').Substring(0, 8)
    $savedCopy = $target + '.before-repair-' + $suffix + '.bak'

    Copy-Item -LiteralPath $target -Destination $savedCopy
    [IO.File]::WriteAllText($target, $corrected, $encoding)

    Write-Host 'Variable name fixed. Starting installer.' -ForegroundColor Green
    Write-Host "Installer backup: $savedCopy"
    exit 0
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
