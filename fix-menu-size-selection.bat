@echo off
setlocal
set "NW_MENU_INSTALLER=%~f0"
powershell.exe -NoLogo -NoProfile -Command "try { $s=[IO.File]::ReadAllText($env:NW_MENU_INSTALLER); $p=$s -split '(?m)^:MENU_FIX_START\r?$',2; & ([scriptblock]::Create($p[1])) } catch { Write-Host $_ -ForegroundColor Red; exit 1 }"
set "RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %RESULT%

:MENU_FIX_START
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetDirectoryName($env:NW_MENU_INSTALLER)
$utf8 = [System.Text.UTF8Encoding]::new($false, $true)
$backup = $null
$touched = New-Object 'System.Collections.Generic.List[string]'
$originals = @{}
$outputDir = Join-Path $root 'assets/normalized-menu'
$madeOutputDirectory = $false

try {
    foreach ($name in @('menu.html', 'menu.js')) {
        if (!(Test-Path -LiteralPath (Join-Path $root $name) -PathType Leaf)) {
            throw "Put this installer beside your existing $name."
        }
    }

    $htmlText = [IO.File]::ReadAllText(
        (Join-Path $root 'menu.html'),
        $utf8
    )

    if (
        $htmlText -notmatch 'menu-catalogue' -or
        $htmlText -notmatch '(?i)</head\s*>' -or
        $htmlText -notmatch '(?i)</body\s*>'
    ) {
        throw 'The expected menu layout was not found. Nothing was changed.'
    }

    $products = @(
        'sunset',
        'moonlight',
        'dreamy',
        'spanish',
        'cloudy',
        'pumpkin',
        'biscoff',
        'americano',
        'strawberry-milk',
        'matcha',
        'oreo',
        'matcha-berry',
        'mango',
        'berry-blue',
        'lychee',
        'apple',
        'strawberry-soda',
        'blueberry'
    )

    foreach ($product in $products) {
        $assetPath = Join-Path $root "assets/transparent-products/$product.png"

        if (!(Test-Path -LiteralPath $assetPath -PathType Leaf)) {
            throw "Missing transparent drink image: assets/transparent-products/$product.png. Nothing was changed."
        }
    }

    if (Test-Path -LiteralPath $outputDir -PathType Leaf) {
        throw 'assets/normalized-menu must be a folder, not a file.'
    }

    Add-Type -AssemblyName System.Drawing

    $normalizerSource = @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;

public static class NawayaCupNormalizer {
  public static byte[] Normalize(string path) {
    using (Bitmap original = new Bitmap(path))
    using (Bitmap image = new Bitmap(
      original.Width,
      original.Height,
      PixelFormat.Format32bppArgb
    )) {
      int w = image.Width, h = image.Height;

      using (Graphics g = Graphics.FromImage(image)) {
        g.CompositingMode = CompositingMode.SourceCopy;
        g.DrawImage(original, new Rectangle(0,0,w,h));
      }

      BitmapData data = image.LockBits(
        new Rectangle(0,0,w,h),
        ImageLockMode.ReadOnly,
        PixelFormat.Format32bppArgb
      );

      int stride = data.Stride;
      byte[] pixels = new byte[stride*h];

      try {
        Marshal.Copy(data.Scan0,pixels,0,pixels.Length);
      }
      finally {
        image.UnlockBits(data);
      }

      int left=w, right=-1, top=h, bottom=-1, visible=0;

      for(int y=0;y<h;y++) {
        for(int x=0;x<w;x++) {
          if(pixels[y*stride+x*4+3]<24) continue;

          visible++;
          left=Math.Min(left,x);
          right=Math.Max(right,x);
          top=Math.Min(top,y);
          bottom=Math.Max(bottom,y);
        }
      }

      if(right<left || visible>w*(double)h*.98) {
        throw new InvalidDataException(
          "Expected a transparent drink cutout: " + path
        );
      }

      // Measure the cup itself, not empty space around the PNG.
      int x0=(int)(w*.45), x1=(int)(w*.55);
      int start=-1, bodyTop=0, bodyBottom=0;

      for(int y=0;y<=h;y++) {
        int count=0;

        if(y<h) {
          for(int x=x0;x<x1;x++) {
            if(pixels[y*stride+x*4+3]>=24) count++;
          }
        }

        bool opaque=y<h && count>=(x1-x0)*.5;

        if(opaque && start<0) start=y;

        if(!opaque && start>=0) {
          if(y-start>bodyBottom-bodyTop) {
            bodyTop=start;
            bodyBottom=y;
          }
          start=-1;
        }
      }

      if(bodyBottom<=bodyTop) {
        throw new InvalidDataException(
          "Could not measure cup: " + path
        );
      }

      double sum=0;
      int rows=0;
      int bodyHeight=bodyBottom-bodyTop;

      for(
        int y=bodyTop+bodyHeight/4;
        y<bodyTop+3*bodyHeight/4;
        y++
      ) {
        int a=w, b=-1;

        for(int x=0;x<w;x++) {
          if(pixels[y*stride+x*4+3]>=24) {
            a=Math.Min(a,x);
            b=Math.Max(b,x);
          }
        }

        if(b>=a) {
          sum+=(a+b+1)/2.0;
          rows++;
        }
      }

      double center=rows>0 ? sum/rows : w/2.0;
      double scale=280.0/bodyHeight;

      float dx=(float)(147.5+(left-center)*scale);
      float dy=(float)(40+(top-bodyTop)*scale);
      float dw=(float)((right-left+1)*scale);
      float dh=(float)((bottom-top+1)*scale);

      if(dx<0 || dy<0 || dx+dw>295 || dy+dh>365) {
        throw new InvalidDataException(
          "Unusual image proportions; original preserved: " + path
        );
      }

      using(Bitmap output=new Bitmap(
        295,365,PixelFormat.Format32bppArgb
      ))
      using(Graphics g=Graphics.FromImage(output))
      using(MemoryStream stream=new MemoryStream()) {
        g.Clear(Color.Transparent);
        g.InterpolationMode=InterpolationMode.HighQualityBicubic;
        g.PixelOffsetMode=PixelOffsetMode.HighQuality;

        g.DrawImage(
          image,
          new RectangleF(dx,dy,dw,dh),
          new RectangleF(left,top,right-left+1,bottom-top+1),
          GraphicsUnit.Pixel
        );

        output.Save(stream,ImageFormat.Png);
        return stream.ToArray();
      }
    }
  }
}
'@

    Add-Type -TypeDefinition $normalizerSource `
        -ReferencedAssemblies @(
            'System.dll',
            ([System.Drawing.Bitmap].Assembly.Location)
        )

    $writes = [ordered]@{}

    foreach ($product in $products) {
        Write-Host "Preparing $product..."

        $assetPath = Join-Path $root "assets/transparent-products/$product.png"

        $writes["assets/normalized-menu/$product-normalized.png"] =
            [NawayaCupNormalizer]::Normalize($assetPath)
    }

    $cssText = @'
.menu-page #menu-catalogue .menu-product-grid {
  align-items: start;
}

.menu-page #menu-catalogue .menu-product {
  height: auto;
  align-self: start;
}

.menu-page #menu-catalogue .nw-menu-visual {
  position: relative;
  display: block;
  flex: 0 0 auto;
  width: min(295px, 100%);
  aspect-ratio: 295 / 365;
  overflow: hidden;
  border-radius: 32px;
  background: transparent;
  transition: background-color .3s ease-out;
}

.menu-page #menu-catalogue .nw-menu-visual .menu-product-image {
  position: absolute !important;
  inset: 0 !important;
  display: block;
  width: 100% !important;
  height: 100% !important;
  max-width: none !important;
  max-height: none !important;
  margin: 0 !important;
  object-fit: contain !important;
  transform: none !important;
  background: transparent !important;
  border: 0 !important;
  border-radius: 0 !important;
  box-shadow: none !important;
}

.menu-page #menu-catalogue .menu-product.is-expanded .nw-menu-visual,
.menu-page #menu-catalogue .menu-product[aria-expanded="true"] .nw-menu-visual {
  background: #fff !important;
}

.menu-page #menu-catalogue .menu-product.nw-menu-food.is-expanded .nw-menu-visual,
.menu-page #menu-catalogue .menu-product.nw-menu-food[aria-expanded="true"] .nw-menu-visual {
  background: #fff0ef !important;
}

.menu-page #menu-catalogue .menu-product-name,
.menu-page #menu-catalogue .menu-inline-details {
  color: white;
}

.menu-page .menu-category-links a[aria-current="true"] {
  background: white !important;
  color: #141311 !important;
  border-color: white !important;
}

@media (max-width: 650px) {
  .menu-page #menu-catalogue .nw-menu-visual {
    border-radius: 24px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .menu-page #menu-catalogue .nw-menu-visual {
    transition: none;
  }
}
'@

    $jsText = @'
(() => {
  'use strict';

  function init() {
    const catalogue = document.getElementById('menu-catalogue');

    if (!catalogue || catalogue.dataset.nwNormalized) return;
    catalogue.dataset.nwNormalized = 'true';

    const drinks = new Set(
      (
        'sunset moonlight dreamy spanish cloudy pumpkin biscoff ' +
        'americano strawberry-milk matcha oreo matcha-berry mango ' +
        'berry-blue lychee apple strawberry-soda blueberry'
      ).split(' ')
    );

    function sync() {
      catalogue.querySelectorAll('.menu-product').forEach(button => {
        const image = button.querySelector('.menu-product-image');
        if (!image) return;

        let visual = image.closest('.nw-menu-visual');

        if (!visual) {
          visual = document.createElement('span');
          visual.className = 'nw-menu-visual';

          image.before(visual);
          visual.append(image);
        }

        const id = button.id.replace(/^product-/, '');

        if (drinks.has(id)) {
          const desired =
            `assets/normalized-menu/${id}-normalized.png`;

          if (image.getAttribute('src') !== desired) {
            image.removeAttribute('srcset');
            image.setAttribute('src', desired);
          }

          image.style.setProperty('filter', 'none', 'important');
        } else if (
          button.closest('#takoyaki') &&
          !button.classList.contains('nw-menu-food')
        ) {
          button.classList.add('nw-menu-food');
        }
      });
    }

    sync();

    new MutationObserver(sync).observe(catalogue, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['class', 'aria-expanded', 'src']
    });

    document.addEventListener('keydown', event => {
      if (event.key !== 'Escape') return;
      catalogue.querySelector('.menu-product.is-expanded')?.click();
    });

    const links = [
      ...document.querySelectorAll('.menu-category-links a')
    ];

    const wrongFood = links.find(link =>
      /^(?:\.\/)?wsdsada\.html(?:[?#].*)?$/i.test(
        link.getAttribute('href') || ''
      )
    );

    if (wrongFood && document.getElementById('takoyaki')) {
      wrongFood.setAttribute('href', '#takoyaki');
    }

    links.forEach(link => {
      link.addEventListener('click', () => {
        const href = link.getAttribute('href') || '';

        if (
          !href.startsWith('#') ||
          !document.getElementById(href.slice(1))
        ) return;

        links.forEach(item => item.removeAttribute('aria-current'));
        link.setAttribute('aria-current', 'true');
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init, {
      once: true
    });
  } else {
    init();
  }
})();
'@

    # Remove obsolete white-image swapping and earlier copies of this update.
    $scriptPattern = '(?is)<script\b[^>]*\bsrc\s*=\s*["''](?:\./)?(?:menu-solid-white|menu-product-state)\.js(?:\?[^"'']*)?["''][^>]*>\s*</script\s*>'
    $stylePattern = '(?is)<link\b[^>]*\bhref\s*=\s*["''](?:\./)?(?:menu-solid-white|menu-product-state)\.css(?:\?[^"'']*)?["''][^>]*>'

    $htmlText = [regex]::Replace($htmlText, $scriptPattern, '')
    $htmlText = [regex]::Replace($htmlText, $stylePattern, '')

    $htmlText = [regex]::Replace(
        $htmlText,
        '(?i)</head\s*>',
        "<link rel=`"stylesheet`" href=`"menu-product-state.css`">`r`n</head>"
    )

    $htmlText = [regex]::Replace(
        $htmlText,
        '(?i)</body\s*>',
        "<script src=`"menu-product-state.js`" defer></script>`r`n</body>"
    )

    $writes['menu-product-state.css'] = $cssText
    $writes['menu-product-state.js'] = $jsText
    $writes['menu.html'] = $htmlText

    # Prepare backups before saving changes.
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $suffix = [guid]::NewGuid().ToString('N').Substring(0, 6)
    $backup = Join-Path $root "backup-menu-selection-$stamp-$suffix"

    [IO.Directory]::CreateDirectory($backup) | Out-Null
    $created = New-Object 'System.Collections.Generic.List[string]'

    foreach ($name in $writes.Keys) {
        $path = Join-Path $root $name

        if (Test-Path -LiteralPath $path -PathType Container) {
            throw "A folder already uses $name."
        }

        $exists = Test-Path -LiteralPath $path -PathType Leaf
        $originals[$name] = $exists

        if ($exists) {
            $destination = Join-Path $backup $name

            [IO.Directory]::CreateDirectory(
                [IO.Path]::GetDirectoryName($destination)
            ) | Out-Null

            Copy-Item -LiteralPath $path -Destination $destination
        } else {
            $created.Add($name)
        }
    }

    [IO.File]::WriteAllText(
        (Join-Path $backup 'created-files.txt'),
        ($created -join "`r`n"),
        $utf8
    )

    if (!(Test-Path -LiteralPath $outputDir -PathType Container)) {
        [IO.Directory]::CreateDirectory($outputDir) | Out-Null
        $madeOutputDirectory = $true
    }

    foreach ($name in $writes.Keys) {
        $touched.Add($name)
        $path = Join-Path $root $name
        $value = $writes[$name]

        if ($value -is [byte[]]) {
            [IO.File]::WriteAllBytes($path, $value)
        } else {
            [IO.File]::WriteAllText($path, [string]$value, $utf8)
        }
    }

    Write-Host ''
    Write-Host 'Menu sizes and selection panels installed.' -ForegroundColor Green
    Write-Host 'Refresh with Ctrl+F5, then click a product.'
    Write-Host 'Your original product images were not changed.'
    Write-Host "Backup: $backup"
    Write-Host 'To undo: restore the backed-up items.'
    Write-Host 'Remove new items listed in created-files.txt.'
    Write-Host 'Nothing was uploaded to GitHub.'
    exit 0
}
catch {
    $problem = $_

    foreach ($name in $touched) {
        $path = Join-Path $root $name

        try {
            if ($originals[$name]) {
                Copy-Item -LiteralPath (Join-Path $backup $name) `
                    -Destination $path -Force
            }
            elseif (Test-Path -LiteralPath $path -PathType Leaf) {
                Remove-Item -LiteralPath $path
            }
        }
        catch {
            Write-Host "Restore $name manually from $backup" `
                -ForegroundColor Yellow
        }
    }

    if ($madeOutputDirectory) {
        try {
            [IO.Directory]::Delete($outputDir, $false)
        } catch {}
    }

    Write-Host $problem.Exception.Message -ForegroundColor Red
    Write-Host $problem.InvocationInfo.PositionMessage

    if ($backup) {
        Write-Host "Backup: $backup"
    }

    exit 1
}
