@echo off
setlocal
set "NAWAYA_PRODUCT_UPDATER=%~f0"

powershell.exe -NoProfile -Command "$text=[IO.File]::ReadAllText($env:NAWAYA_PRODUCT_UPDATER);$parts=[regex]::Split($text,'(?m)^# BEGIN_POWERSHELL\r?$');if($parts.Length -ne 2){throw 'Could not read updater.'};& ([scriptblock]::Create($parts[1]))"

set "RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %RESULT%

# BEGIN_POWERSHELL
$ErrorActionPreference = "Stop"
$stage = $null
$exitCode = 0

try {
    $folder = Split-Path -LiteralPath $env:NAWAYA_PRODUCT_UPDATER
    $pages = @("index.html", "menu.html")

    foreach ($name in $pages) {
        $path = Join-Path $folder $name

        if (!(Test-Path -LiteralPath $path)) {
            throw "$name was not found. Put this updater beside index.html and menu.html."
        }

        $page = [IO.File]::ReadAllText($path)

        if ($page -notmatch '(?i)</head>') {
            throw "Could not find the closing head tag in $name."
        }
    }

    if (!(Get-Command curl.exe -ErrorAction SilentlyContinue)) {
        throw "curl.exe was not found on this computer."
    }

    $assetJson = @'
{
  "sunset": "https://www.figma.com/api/mcp/asset/c3016a99-dee7-4cf1-afc0-7b64dd2dbc4d",
  "moonlight": "https://www.figma.com/api/mcp/asset/8358d3da-0192-499d-8852-24d1f0be600e",
  "dreamy": "https://www.figma.com/api/mcp/asset/48df65ac-9d89-41ea-a1f6-da402b73f3f0",
  "spanish": "https://www.figma.com/api/mcp/asset/32001eac-a35d-4f20-9a0d-f838ab1376c0",
  "cloudy": "https://www.figma.com/api/mcp/asset/d9d39b3f-129b-4c5e-a81d-c50680796514",
  "pumpkin": "https://www.figma.com/api/mcp/asset/aca6178b-febf-47c3-a01d-297b271cd86c",
  "biscoff": "https://www.figma.com/api/mcp/asset/34430e54-acd5-417e-9dc9-1020327f657d",
  "americano": "https://www.figma.com/api/mcp/asset/c24d130b-877d-41b9-9616-bc11384aa519",
  "strawberry-milk": "https://www.figma.com/api/mcp/asset/fe7f288a-40e0-4ee3-9405-efe2de09398f",
  "matcha": "https://www.figma.com/api/mcp/asset/2d713272-c5bc-46b2-b9b9-7e2c3a05351e",
  "oreo": "https://www.figma.com/api/mcp/asset/66ff4be3-ef7b-472a-bb2a-5b9baebd1945",
  "matcha-berry": "https://www.figma.com/api/mcp/asset/5d0d22e9-2b03-4864-9a4a-f0ab03360c41",
  "mango": "https://www.figma.com/api/mcp/asset/4eb648a7-2f3c-4603-897f-8bb5be2d7583",
  "berry-blue": "https://www.figma.com/api/mcp/asset/2bf178c6-51a5-469e-9ced-54865bcb57e7",
  "lychee": "https://www.figma.com/api/mcp/asset/f3b1a8ca-d79e-4e10-ab30-a1f6ae6457d2",
  "apple": "https://www.figma.com/api/mcp/asset/847d82cb-1760-4372-88ab-33ab0c2e3e1b",
  "strawberry-soda": "https://www.figma.com/api/mcp/asset/599e3e1d-0606-4a36-b759-73804f418b46",
  "blueberry": "https://www.figma.com/api/mcp/asset/0e656e4c-c949-4e2c-8695-172679cd8ac0",
  "cheese": "https://www.figma.com/api/mcp/asset/a79c58a3-77e2-4a0f-b6fa-382a5e877b3b",
  "crabstick": "https://www.figma.com/api/mcp/asset/04ac1a2f-5b72-4cfc-89db-6770c5dafa4e",
  "ham-veggies": "https://www.figma.com/api/mcp/asset/93c99228-3b16-498f-ab1b-cda185eee9c0",
  "ham-cheese": "https://www.figma.com/api/mcp/asset/ea0088bb-7dd5-4070-81f7-b079a31fc4d2",
  "crabstick-veggies": "https://www.figma.com/api/mcp/asset/2eefa201-915f-4db2-a7fa-d09e96e1b64e"
}
'@

    $assets = ConvertFrom-Json $assetJson

    $stage = Join-Path $folder (
        ".transparent-products-" + [guid]::NewGuid().ToString("N")
    )

    New-Item -ItemType Directory -Path $stage | Out-Null

    Write-Host ""
    Write-Host "Downloading 23 transparent product images..."
    Write-Host "Keep this window open."
    Write-Host ""

    foreach ($asset in $assets.PSObject.Properties) {
        $filename = $asset.Name + ".png"
        $destination = Join-Path $stage $filename

        Write-Host ("Downloading: " + $filename)

        & curl.exe -fL --retry 2 --connect-timeout 20 --max-time 90 $asset.Value -o $destination

        if ($LASTEXITCODE -ne 0) {
            throw (
                "Download failed for " + $filename +
                ". The temporary link may have expired. Your website pages have not been changed."
            )
        }
    }

    $javascript = @'
(() => {
  "use strict";

  const productNames = new Set([
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
  ]);

  const shadow =
    "drop-shadow(0 0 1px rgba(255,255,255,0.2)) " +
    "drop-shadow(0 15px 12px rgba(0,0,0,0.18)) " +
    "drop-shadow(0 3px 3px rgba(0,0,0,0.08))";

  function setImportant(element, property, value) {
    if (
      element.style.getPropertyValue(property) !== value ||
      element.style.getPropertyPriority(property) !== "important"
    ) {
      element.style.setProperty(property, value, "important");
    }
  }

  function updateProductImages() {
    const images = document.querySelectorAll(
      ".featured img, " +
      "#menu-featured img, " +
      ".menu-product-image"
    );

    images.forEach(image => {
      const source = image.getAttribute("src") || "";

      const match = source.match(
        /(?:^|\/)([^/?#]+)\.png(?:[?#].*)?$/i
      );

      if (!match) return;

      const name = match[1]
        .replace(/-white$/i, "")
        .toLowerCase();

      if (!productNames.has(name)) return;

      const desired =
        `assets/transparent-products/${name}.png`;

      if (source !== desired) {
        image.removeAttribute("srcset");
        image.setAttribute("src", desired);
      }

      /*
       * Override earlier solid-background fixes.
       * Keep all transforms and carousel movement unchanged.
       */
      setImportant(image, "background", "transparent");
      setImportant(image, "background-image", "none");
      setImportant(image, "border", "0px");
      setImportant(image, "box-shadow", "none");
      setImportant(image, "backdrop-filter", "none");
      setImportant(image, "-webkit-backdrop-filter", "none");
      setImportant(image, "mix-blend-mode", "normal");
      setImportant(image, "filter", shadow);

      const holder = image.closest(
        ".drink, " +
        ".menu-featured-product, " +
        ".smooth-menu-item, " +
        ".menu-product"
      );

      if (holder) {
        setImportant(holder, "background", "transparent");
        setImportant(holder, "background-image", "none");
        setImportant(holder, "box-shadow", "none");
        setImportant(holder, "backdrop-filter", "none");
        setImportant(holder, "-webkit-backdrop-filter", "none");
      }
    });
  }

  function initialize() {
    updateProductImages();

    let scheduled = false;

    const observer = new MutationObserver(() => {
      if (scheduled) return;

      scheduled = true;

      requestAnimationFrame(() => {
        scheduled = false;
        updateProductImages();
      });
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ["src", "class"]
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener(
      "DOMContentLoaded",
      initialize,
      { once: true }
    );
  } else {
    initialize();
  }
})();
'@

    $backup = Join-Path $folder (
        "backup-transparent-products-" +
        (Get-Date -Format "yyyyMMdd-HHmmss-fff")
    )

    New-Item -ItemType Directory -Path $backup | Out-Null

    foreach ($name in @(
        "index.html",
        "menu.html",
        "clean-product-images.js"
    )) {
        $path = Join-Path $folder $name

        if (Test-Path -LiteralPath $path) {
            Copy-Item -LiteralPath $path -Destination (
                Join-Path $backup $name
            )
        }
    }

    $assetFolder = Join-Path $folder "assets\transparent-products"

    New-Item -ItemType Directory -Force -Path $assetFolder | Out-Null

    foreach ($asset in $assets.PSObject.Properties) {
        $filename = $asset.Name + ".png"
        $existing = Join-Path $assetFolder $filename

        if (Test-Path -LiteralPath $existing) {
            $imageBackup = Join-Path $backup "product-images"

            New-Item -ItemType Directory -Force -Path $imageBackup | Out-Null

            Copy-Item -LiteralPath $existing -Destination (
                Join-Path $imageBackup $filename
            )
        }

        Copy-Item -LiteralPath (Join-Path $stage $filename) -Destination $existing -Force
    }

    $encoding = [System.Text.UTF8Encoding]::new($false)

    [IO.File]::WriteAllText(
        (Join-Path $folder "clean-product-images.js"),
        $javascript,
        $encoding
    )

    # Remove superseded background helpers from these two pages.
    # Keep menu.js, smooth carousel, contact, and other scripts.

    $oldScriptPattern = '(?is)<script\b(?=[^>]*\bsrc\s*=\s*["''](?:\./)?(?:home-clean-drinks|menu-solid-white|clean-product-images)\.js(?:\?[^"'']*)?["''])[^>]*>\s*</script>\s*'

    $oldStylePattern = '(?is)<link\b(?=[^>]*\bhref\s*=\s*["''](?:\./)?(?:home-clean-drinks|menu-solid-white)\.css(?:\?[^"'']*)?["''])[^>]*>\s*'

    $tag = '<script id="nawaya-clean-product-images" src="clean-product-images.js" defer></script>'

    foreach ($name in $pages) {
        $path = Join-Path $folder $name
        $page = [IO.File]::ReadAllText($path)

        $page = [regex]::Replace(
            $page,
            $oldScriptPattern,
            ""
        )

        $page = [regex]::Replace(
            $page,
            $oldStylePattern,
            ""
        )

        $page = [regex]::Replace(
            $page,
            '(?i)</head>',
            "`r`n" + $tag + "`r`n</head>"
        )

        [IO.File]::WriteAllText(
            $path,
            $page,
            $encoding
        )

        Write-Host ("Updated: " + $name)
    }

    Write-Host ""
    Write-Host "DONE! Both pages now use transparent product images." -ForegroundColor Green
    Write-Host "Soft shadows added to products and carousels."
    Write-Host "Your existing carousel motion was preserved."
    Write-Host "Dark page sections and hero photos were not changed."
    Write-Host ("Backup: " + $backup)
    Write-Host ""
    Write-Host "Refresh BOTH pages with Ctrl + F5."
}
catch {
    Write-Host ""
    Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
    $exitCode = 1
}
finally {
    if ($stage -and (Test-Path -LiteralPath $stage)) {
        Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
    }
}

exit $exitCode
