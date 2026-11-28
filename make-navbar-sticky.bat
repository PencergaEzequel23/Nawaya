@echo off
setlocal
set "NW_STICKY_INSTALLER=%~f0"
powershell.exe -NoLogo -NoProfile -Command "try { $s=[IO.File]::ReadAllText($env:NW_STICKY_INSTALLER); $p=$s -split '(?m)^:STICKY_START\r?$',2; & ([scriptblock]::Create($p[1])) } catch { Write-Host $_ -ForegroundColor Red; exit 1 }"
set "RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %RESULT%

:STICKY_START
$ErrorActionPreference = 'Stop'
$folder = [IO.Path]::GetDirectoryName($env:NW_STICKY_INSTALLER)
$encoding = [System.Text.UTF8Encoding]::new($false, $true)
$snapshot = $null
$touched = New-Object 'System.Collections.Generic.List[string]'

try {
    foreach ($name in @(
        'index.html',
        'nawaya-nav-reviews.css',
        'nawaya-nav-reviews.js'
    )) {
        if (!(Test-Path -LiteralPath (Join-Path $folder $name) -PathType Leaf)) {
            throw "Missing $name. Put this beside index.html and run the navbar/reviews installer first."
        }
    }

    $css = @'
/* NW-STICKY-START */
:root {
  --nw-header-height: 97px;
  --nw-category-height: 0px;
}

html {
  scroll-padding-top: calc(var(--nw-header-height) + 16px) !important;
}

header.site-header,
header.site-header.nw-nav {
  position: sticky !important;
  top: 0 !important;
  z-index: 1000 !important;
}

header.site-header.nw-sticky-scrolled {
  box-shadow: 0 4px 16px rgb(0 0 0 / 22%);
}

body #menu-categories.menu-categories {
  position: sticky !important;
  top: var(--nw-header-height) !important;
  z-index: 900 !important;
}

.menu-page .menu-category,
.menu-page .menu-product {
  scroll-margin-top: var(--nw-category-height) !important;
}
/* NW-STICKY-END */
'@

    $js = @'
/* NW-STICKY-START */
(() => {
  'use strict';

  if (window.nwStickyInstalled) return;

  const header = document.querySelector('header.site-header');
  if (!header) return;

  window.nwStickyInstalled = true;

  const bar = document.getElementById('menu-categories');
  const root = document.documentElement;

  function measure() {
    root.style.setProperty(
      '--nw-header-height',
      Math.ceil(header.getBoundingClientRect().height) + 'px'
    );

    root.style.setProperty(
      '--nw-category-height',
      (bar ? Math.ceil(bar.getBoundingClientRect().height) : 0) + 'px'
    );
  }

  function shade() {
    header.classList.toggle(
      'nw-sticky-scrolled',
      window.scrollY > 8
    );
  }

  if (window.ResizeObserver) {
    const observer = new ResizeObserver(measure);
    observer.observe(header);
    if (bar) observer.observe(bar);
  }

  window.addEventListener('resize', measure, { passive: true });
  window.addEventListener('scroll', shade, { passive: true });

  window.addEventListener('pageshow', () => {
    measure();
    shade();
  });

  if (document.fonts?.ready) {
    document.fonts.ready.then(measure);
  }

  measure();
  shade();
})();
/* NW-STICKY-END */
'@

    $writes = [ordered]@{}

    # Replace an earlier copy of this patch if run again.
    $block = '(?s)/\* NW-STICKY-START \*/.*?/\* NW-STICKY-END \*/'

    foreach ($name in @(
        'nawaya-nav-reviews.css',
        'nawaya-nav-reviews.js'
    )) {
        $previous = [IO.File]::ReadAllText(
            (Join-Path $folder $name),
            $encoding
        )

        $previous = [regex]::Replace($previous, $block, '')

        $addition = if ($name.EndsWith('.css')) {
            $css
        } else {
            $js
        }

        $writes[$name] = $previous + "`r`n" + $addition + "`r`n"
    }

    # Account for the navbar when using menu category scrolling.
    $menuPath = Join-Path $folder 'menu.js'

    if (Test-Path -LiteralPath $menuPath -PathType Leaf) {
        $text = [IO.File]::ReadAllText($menuPath, $encoding)

        if (!$text.Contains('nw-sticky-offset')) {
            $pattern = '(?s)const\s+stickyOffset\s*=\s*target\s*===\s*categoryBar\s*\?\s*0\s*:\s*categoryBar\.getBoundingClientRect\(\)\.height\s*\+\s*16\s*;'

            $found = [regex]::Match($text, $pattern)

            if (!$found.Success) {
                throw 'The menu scrolling layout differs from the expected version. Nothing was changed.'
            }

            $replacement = 'const stickyOffset = /* nw-sticky-offset */ (document.querySelector(".site-header")?.getBoundingClientRect().height || 0) + (target === categoryBar ? 0 : categoryBar.getBoundingClientRect().height + 16);'

            $writes['menu.js'] = $text.Remove(
                $found.Index,
                $found.Length
            ).Insert($found.Index, $replacement)
        }
    }

    # Account for the navbar when a featured drink opens its product.
    $carouselPath = Join-Path $folder 'nwc-fixed.js'

    if (Test-Path -LiteralPath $carouselPath -PathType Leaf) {
        $text = [IO.File]::ReadAllText($carouselPath, $encoding)

        if (!$text.Contains('nw-sticky-offset')) {
            $found = [regex]::Match(
                $text,
                '(?s)\bconst\s+offset\s*=\s*(?<expr>[^;]*?menu-categories[^;]*);'
            )

            if (!$found.Success) {
                throw 'The carousel scrolling layout differs from the expected version. Nothing was changed.'
            }

            $replacement =
                'const offset = /* nw-sticky-offset */ ' +
                '(document.querySelector(".site-header")?.getBoundingClientRect().height || 0) + (' +
                $found.Groups['expr'].Value +
                ');'

            $writes['nwc-fixed.js'] = $text.Remove(
                $found.Index,
                $found.Length
            ).Insert($found.Index, $replacement)
        }
    }

    # Back up every affected item before changing anything.
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $suffix = [guid]::NewGuid().ToString('N').Substring(0, 6)

    $snapshot = Join-Path $folder "backup-sticky-nav-$stamp-$suffix"
    [IO.Directory]::CreateDirectory($snapshot) | Out-Null

    foreach ($name in $writes.Keys) {
        Copy-Item -LiteralPath (Join-Path $folder $name) `
            -Destination (Join-Path $snapshot $name)
    }

    foreach ($name in $writes.Keys) {
        $touched.Add($name)

        [IO.File]::WriteAllText(
            (Join-Path $folder $name),
            [string]$writes[$name],
            $encoding
        )
    }

    Write-Host ''
    Write-Host 'Sticky navbar installed. Refresh with Ctrl+F5.' -ForegroundColor Green
    Write-Host 'The menu category bar stays below the navbar.'
    Write-Host "Backup: $snapshot"
    Write-Host 'To undo: copy the backed-up items back into the website folder.'
    Write-Host 'Nothing was uploaded to GitHub.'
    exit 0
}
catch {
    $problem = $_

    foreach ($name in $touched) {
        try {
            Copy-Item -LiteralPath (Join-Path $snapshot $name) `
                -Destination (Join-Path $folder $name) -Force
        }
        catch {
            Write-Host "Restore $name manually from $snapshot" `
                -ForegroundColor Yellow
        }
    }

    Write-Host $problem.Exception.Message -ForegroundColor Red

    if ($snapshot) {
        Write-Host "Backup: $snapshot"
    }

    exit 1
}
