@echo off
setlocal
set "NAWAYA_WHITE_UPDATER=%~f0"

powershell.exe -NoProfile -Command "$text=[IO.File]::ReadAllText($env:NAWAYA_WHITE_UPDATER);$parts=[regex]::Split($text,'(?m)^# BEGIN_POWERSHELL\r?$');if($parts.Length -ne 2){throw 'Could not read updater.'};& ([scriptblock]::Create($parts[1]))"

set "RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %RESULT%

# BEGIN_POWERSHELL
$ErrorActionPreference = "Stop"

try {
    $folder = Split-Path -LiteralPath $env:NAWAYA_WHITE_UPDATER
    $htmlPath = Join-Path $folder "menu.html"
    $assetsPath = Join-Path $folder "assets\menu"

    if (!(Test-Path -LiteralPath $htmlPath)) {
        throw "menu.html not found. Put this updater beside menu.html."
    }

    if (!(Test-Path -LiteralPath $assetsPath)) {
        throw "assets\menu not found. Download the menu images first."
    }

    $html = [IO.File]::ReadAllText($htmlPath)

    if ($html -notmatch '(?i)</head>') {
        throw "Could not find the closing head tag in menu.html."
    }

    $products = @(
        "sunset",
        "moonlight",
        "dreamy",
        "spanish",
        "cloudy",
        "pumpkin",
        "biscoff",
        "americano",
        "strawberry-milk",
        "matcha",
        "oreo",
        "matcha-berry",
        "mango",
        "berry-blue",
        "lychee",
        "apple",
        "strawberry-soda",
        "blueberry",
        "cheese",
        "crabstick",
        "ham-veggies",
        "ham-cheese",
        "crabstick-veggies"
    )

    $missing = @()

    foreach ($name in $products) {
        $path = Join-Path $assetsPath "$name.png"

        if (!(Test-Path -LiteralPath $path)) {
            $missing += "$name.png"
        }
    }

    if ($missing.Count -gt 0) {
        throw ("Missing product images: " + ($missing -join ", "))
    }

    Add-Type -AssemblyName System.Drawing

    Write-Host ""
    Write-Host "Creating solid-white product images..."

    foreach ($name in $products) {
        $sourcePath = Join-Path $assetsPath "$name.png"
        $outputPath = Join-Path $assetsPath "$name-white.png"
        $temporaryPath = Join-Path $assetsPath "$name-white.tmp.png"

        $source = $null
        $bitmap = $null
        $graphics = $null

        try {
            $source = [System.Drawing.Image]::FromFile($sourcePath)

            $bitmap = [System.Drawing.Bitmap]::new(
                $source.Width,
                $source.Height,
                [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
            )

            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

            $graphics.Clear([System.Drawing.Color]::White)

            $graphics.DrawImage(
                $source,
                0,
                0,
                $source.Width,
                $source.Height
            )

            $bitmap.Save(
                $temporaryPath,
                [System.Drawing.Imaging.ImageFormat]::Png
            )
        }
        finally {
            if ($graphics) { $graphics.Dispose() }
            if ($bitmap) { $bitmap.Dispose() }
            if ($source) { $source.Dispose() }
        }

        Move-Item -LiteralPath $temporaryPath -Destination $outputPath -Force
        Write-Host ("Created: " + $name + "-white.png")
    }

    $css = @'
/* Solid white background for the selected product image. */

.menu-page .menu-product.is-expanded {
  background: transparent !important;
  backdrop-filter: none !important;
  -webkit-backdrop-filter: none !important;
  opacity: 1 !important;
}

.menu-page .menu-product.is-expanded .menu-product-image {
  background: #ffffff !important;
  background-image: none !important;
  opacity: 1 !important;
  filter: none !important;
  backdrop-filter: none !important;
  -webkit-backdrop-filter: none !important;
  mix-blend-mode: normal !important;
  border: 2px solid #ffffff !important;
  border-radius: 32px !important;
  box-shadow: 0 8px 24px rgb(0 0 0 / 20%) !important;
  transform: none !important;
  color-scheme: only light;
}

.menu-page .menu-product.is-expanded .menu-product-name,
.menu-page .menu-product.is-expanded .menu-inline-details {
  color: #ffffff !important;
  opacity: 1 !important;
}

@media (max-width: 650px) {
  .menu-page .menu-product.is-expanded .menu-product-image {
    border-radius: 24px !important;
  }
}
'@

    $javascript = @'
(() => {
  "use strict";

  function initializeSolidProducts() {
    const catalogue = document.querySelector("#menu-catalogue");

    if (!catalogue) return;

    function updateProductImages() {
      catalogue.querySelectorAll(".menu-product").forEach(button => {
        const image = button.querySelector(".menu-product-image");

        if (!image) return;

        if (!image.dataset.nawayaOriginalSrc) {
          const currentSource = image.getAttribute("src");

          if (!currentSource) return;

          image.dataset.nawayaOriginalSrc = currentSource.replace(
            /-white\.png(?=([?#]|$))/i,
            ".png"
          );
        }

        const originalSource = image.dataset.nawayaOriginalSrc;

        const desiredSource = button.classList.contains("is-expanded")
          ? originalSource.replace(
              /\.png(?=([?#]|$))/i,
              "-white.png"
            )
          : originalSource;

        if (image.getAttribute("src") !== desiredSource) {
          image.setAttribute("src", desiredSource);
        }
      });
    }

    const observer = new MutationObserver(updateProductImages);

    observer.observe(catalogue, {
      subtree: true,
      childList: true,
      attributes: true,
      attributeFilter: ["class"]
    });

    updateProductImages();
  }

  if (document.readyState === "loading") {
    document.addEventListener(
      "DOMContentLoaded",
      initializeSolidProducts,
      { once: true }
    );
  } else {
    initializeSolidProducts();
  }
})();
'@

    $backupPath = "$htmlPath.before-solid-white.bak"

    if (!(Test-Path -LiteralPath $backupPath)) {
        Copy-Item -LiteralPath $htmlPath -Destination $backupPath
    }

    $cssTag = '<link id="nawaya-solid-white-css" rel="stylesheet" href="menu-solid-white.css">'
    $jsTag = '<script id="nawaya-solid-white-js" src="menu-solid-white.js" defer></script>'

    $additions = ""

    if (!$html.Contains('id="nawaya-solid-white-css"')) {
        $additions += "`r`n" + $cssTag
    }

    if (!$html.Contains('id="nawaya-solid-white-js"')) {
        $additions += "`r`n" + $jsTag
    }

    if ($additions.Length -gt 0) {
        $html = [regex]::Replace(
            $html,
            '(?i)</head>',
            $additions + "`r`n</head>"
        )
    }

    $encoding = [System.Text.UTF8Encoding]::new($false)

    [IO.File]::WriteAllText(
        (Join-Path $folder "menu-solid-white.css"),
        $css,
        $encoding
    )

    [IO.File]::WriteAllText(
        (Join-Path $folder "menu-solid-white.js"),
        $javascript,
        $encoding
    )

    [IO.File]::WriteAllText(
        $htmlPath,
        $html,
        $encoding
    )

    Write-Host ""
    Write-Host "DONE! Solid-white product backgrounds are installed." -ForegroundColor Green
    Write-Host "Your original product images were preserved."
    Write-Host "menu.html was backed up."
    Write-Host ""
    Write-Host "Refresh your website with Ctrl + F5, then click a product."
}
catch {
    Write-Host ""
    Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
