@echo off
setlocal
title Nawaya - Consistent Drink Sizes
set "NAWAYA_PATCH_SELF=%~f0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:NAWAYA_PATCH_SELF); $p=[regex]::Split($t,'(?m)^#===(?:POWERSHELL|CSS|JAVASCRIPT|END)===\r?$'); & ([scriptblock]::Create($p[1]))"
set "PATCH_RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %PATCH_RESULT%
#===POWERSHELL===
$ErrorActionPreference = 'Stop'
$root = Split-Path -LiteralPath $env:NAWAYA_PATCH_SELF
Set-Location -LiteralPath $root
$utf8 = New-Object System.Text.UTF8Encoding($false)
$backup = $null
$changed = $false

$generated = @(
  'nawaya-consistent.css',
  'nawaya-consistent.js',
  'assets/consistent-products'
)

$targets = @('index.html', 'menu.html') + $generated

try {
  foreach ($name in @('index.html', 'menu.html', 'menu.js')) {
    if (!(Test-Path -LiteralPath (Join-Path $root $name) -PathType Leaf)) {
      throw "Put this BAT in your Nawaya website folder, beside index.html and menu.html. Missing: $name"
    }
  }

  $full = [IO.File]::ReadAllText($env:NAWAYA_PATCH_SELF)

  $parts = [regex]::Split(
    $full,
    '(?m)^#===(?:POWERSHELL|CSS|JAVASCRIPT|END)===\r?$'
  )

  if ($parts.Count -ne 5) {
    throw 'Incomplete BAT. Copy everything, including the final END marker.'
  }

  $ids = @(
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
    'blueberry',
    'cheese',
    'crabstick',
    'ham-veggies',
    'ham-cheese',
    'crabstick-veggies'
  )

  foreach ($id in $ids) {
    $source = Join-Path $root "assets/transparent-products/$id.png"

    if (!(Test-Path -LiteralPath $source)) {
      throw "Missing assets/transparent-products/$id.png. Use the complete Nawaya project from GitHub. Nothing has been changed."
    }
  }

  $pages = @{}

  foreach ($name in @('index.html', 'menu.html')) {
    $html = [IO.File]::ReadAllText((Join-Path $root $name))

    if ($html -notmatch '(?i)</head\s*>') {
      throw "$name is missing its closing head tag."
    }

    # Remove competing carousel/image updaters.
    # Keep menu.js, product data, and product-detail interactions.
    $old = '(?is)<script\b(?=[^>]*\bsrc\s*=\s*["''][^"'']*(?:home-carousel|menu-smooth-carousel|clean-product-images|menu-solid-white|nawaya-consistent)\.js(?:\?[^"'']*)?["''])[^>]*>\s*</script\s*>'

    $html = [regex]::Replace($html, $old, '')

    $html = [regex]::Replace(
      $html,
      '(?is)<link\b(?=[^>]*\bhref\s*=\s*["''][^"'']*nawaya-consistent\.css(?:\?[^"'']*)?["''])[^>]*>',
      ''
    )

    $tags = "`r`n<link rel=`"stylesheet`" href=`"nawaya-consistent.css?v=1`">`r`n<script src=`"nawaya-consistent.js?v=1`" defer></script>`r`n</head>"

    $pages[$name] = [regex]::Replace(
      $html,
      '(?i)</head\s*>',
      [System.Text.RegularExpressions.MatchEvaluator]{
        param($m)
        $tags
      }
    )
  }

  Add-Type -AssemblyName System.Drawing

  # Normalize transparent margins without stretching the artwork.
  # Original images remain untouched.
  Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;

public static class NawayaSizing {
  public static void Normalize(
    string source,
    string target,
    bool food
  ) {
    using (var input = new Bitmap(source))
    using (var scan = new Bitmap(
      input.Width,
      input.Height,
      PixelFormat.Format32bppArgb
    )) {
      using (var g = Graphics.FromImage(scan)) {
        g.DrawImageUnscaled(input, 0, 0);
      }

      var rect = new Rectangle(
        0,
        0,
        scan.Width,
        scan.Height
      );

      var data = scan.LockBits(
        rect,
        ImageLockMode.ReadOnly,
        PixelFormat.Format32bppArgb
      );

      int left = scan.Width;
      int top = scan.Height;
      int right = -1;
      int bottom = -1;

      try {
        var row = new byte[scan.Width * 4];

        for (int y = 0; y < scan.Height; y++) {
          Marshal.Copy(
            IntPtr.Add(data.Scan0, y * data.Stride),
            row,
            0,
            row.Length
          );

          for (int x = 0; x < scan.Width; x++) {
            if (row[x * 4 + 3] <= 12) continue;

            left = Math.Min(left, x);
            right = Math.Max(right, x);
            top = Math.Min(top, y);
            bottom = Math.Max(bottom, y);
          }
        }
      }
      finally {
        scan.UnlockBits(data);
      }

      if (right < left) {
        throw new Exception(
          "Empty product image: " + source
        );
      }

      int cw = food ? 600 : 480;
      int ch = food ? 420 : 600;

      var crop = new Rectangle(
        left,
        top,
        right - left + 1,
        bottom - top + 1
      );

      float scale = Math.Min(
        (cw - 48f) / crop.Width,
        (ch - 48f) / crop.Height
      );

      float w = crop.Width * scale;
      float h = crop.Height * scale;

      using (var output = new Bitmap(
        cw,
        ch,
        PixelFormat.Format32bppArgb
      )) {
        using (var g = Graphics.FromImage(output)) {
          g.Clear(Color.Transparent);

          g.InterpolationMode =
            InterpolationMode.HighQualityBicubic;

          g.PixelOffsetMode =
            PixelOffsetMode.HighQuality;

          g.CompositingQuality =
            CompositingQuality.HighQuality;

          g.DrawImage(
            scan,
            new RectangleF(
              (cw - w) / 2,
              ch - 24 - h,
              w,
              h
            ),
            crop,
            GraphicsUnit.Pixel
          );
        }

        output.Save(target, ImageFormat.Png);
      }
    }
  }
}
'@

  $backup = Join-Path $root (
    'backup-consistent-sizes-' +
    (Get-Date -Format 'yyyyMMdd-HHmmss') +
    '-' +
    [guid]::NewGuid().ToString('N').Substring(0,6)
  )

  New-Item -ItemType Directory -Path $backup | Out-Null

  foreach ($name in $targets) {
    $source = Join-Path $root $name

    if (Test-Path -LiteralPath $source) {
      $dest = Join-Path $backup $name

      [IO.Directory]::CreateDirectory(
        (Split-Path -Parent $dest)
      ) | Out-Null

      Copy-Item `
        -LiteralPath $source `
        -Destination $dest `
        -Recurse
    }
  }

  # Generate a one-click restore option.
  $restore = @(
    '@echo off',
    'setlocal',
    'pushd "%~dp0.."',
    'if errorlevel 1 exit /b 1'
  )

  foreach ($name in $targets) {
    $win = $name.Replace('/', '\')

    if (Test-Path -LiteralPath (Join-Path $backup $name)) {
      if ($name -eq 'assets/consistent-products') {
        $restore += "if exist `"$win`" rmdir /s /q `"$win`""
        $restore += "xcopy `"%~dp0$win`" `"$win\`" /E /I /Y >nul"
      }
      else {
        $restore += "copy /Y `"%~dp0$win`" `"$win`" >nul"
      }
    }
    else {
      if ($name -eq 'assets/consistent-products') {
        $restore += "if exist `"$win`" rmdir /s /q `"$win`""
      }
      else {
        $restore += "if exist `"$win`" del /q `"$win`""
      }
    }
  }

  $restore += @(
    'popd',
    'echo Restored. Refresh your browser with Ctrl+F5.',
    'pause'
  )

  [IO.File]::WriteAllText(
    (Join-Path $backup 'RESTORE.bat'),
    ($restore -join "`r`n"),
    $utf8
  )

  $changed = $true

  $output = Join-Path $root 'assets/consistent-products'

  [IO.Directory]::CreateDirectory($output) | Out-Null

  Write-Host 'Normalizing 23 product images...'
  Write-Host 'Original images stay untouched.'

  foreach ($id in $ids) {
    $food = @(
      'cheese',
      'crabstick',
      'ham-veggies',
      'ham-cheese',
      'crabstick-veggies'
    ) -contains $id

    [NawayaSizing]::Normalize(
      (Join-Path $root "assets/transparent-products/$id.png"),
      (Join-Path $output "$id.png"),
      $food
    )
  }

  [IO.File]::WriteAllText(
    (Join-Path $root 'nawaya-consistent.css'),
    $parts[2].Trim(),
    $utf8
  )

  [IO.File]::WriteAllText(
    (Join-Path $root 'nawaya-consistent.js'),
    $parts[3].Trim(),
    $utf8
  )

  foreach ($name in @('index.html', 'menu.html')) {
    [IO.File]::WriteAllText(
      (Join-Path $root $name),
      $pages[$name],
      $utf8
    )
  }

  Write-Host ''
  Write-Host 'DONE: Consistent menu sizes and matching carousels.' -ForegroundColor Green
  Write-Host 'Open index.html or menu.html, then press Ctrl+F5.'
  Write-Host "Backup and undo: $backup\RESTORE.bat"
  Write-Host 'No administrator rights or internet connection needed.'

  exit 0
}
catch {
  $failure = $_.Exception.Message

  if ($changed -and $backup) {
    try {
      foreach ($name in $targets) {
        $live = Join-Path $root $name
        $saved = Join-Path $backup $name

        if (Test-Path -LiteralPath $live) {
          Remove-Item `
            -LiteralPath $live `
            -Recurse `
            -Force
        }

        if (Test-Path -LiteralPath $saved) {
          Copy-Item `
            -LiteralPath $saved `
            -Destination $live `
            -Recurse
        }
      }

      Write-Host 'Update cancelled. Previous version restored.'
    }
    catch {
      Write-Host "Restore manually from: $backup" -ForegroundColor Yellow
    }
  }

  Write-Host "ERROR: $failure" -ForegroundColor Red

  exit 1
}
#===CSS===
/* Shared featured-carousel sizing */

.nw-featured {
  padding: 54px 24px 48px;
  background: #fff;
  color: #141311;
  text-align: center;
}

.nw-featured > h2 {
  margin: 0;
  font-size: 48px;
  line-height: 1.1;
  font-weight: 800;
  text-transform: uppercase;
}

.nw-featured .nw-row {
  display: grid;
  grid-template-columns: 48px minmax(0, 1fr) 48px;
  align-items: center;
  gap: 16px;
  max-width: 1240px;
  margin: 24px auto 0;
}

.nw-featured .nw-stage {
  position: relative;
  height: 540px;
  overflow: hidden;
  touch-action: pan-y;
  isolation: isolate;
}

.nw-featured .nw-item {
  position: absolute;
  left: 50%;
  top: 50%;
  width: 42%;
  max-width: 432px;
  height: 100%;
  margin: 0;
  padding: 0;
  border: 0;
  border-radius: 0;
  background: transparent;
  cursor: pointer;
  transform-origin: center;
  will-change: transform, opacity;
  transition: none;
}

.nw-featured .nw-item img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: contain;
  pointer-events: none;
  user-select: none;
  -webkit-user-drag: none;
  filter: drop-shadow(0 12px 10px rgb(0 0 0 / 14%));
}

.nw-featured .nw-arrow {
  display: grid;
  place-items: center;
  width: 48px;
  height: 48px;
  border: 0;
  border-radius: 50%;
  padding: 0;
  background: transparent;
  color: #141311;
  font: inherit;
  font-size: 32px;
  cursor: pointer;
}

.nw-featured .nw-arrow:hover {
  background: #f3efeb;
}

.nw-featured .nw-caption {
  min-height: 100px;
  margin: 20px auto 0;
  max-width: 720px;
}

.nw-featured .nw-title {
  margin: 0;
  font-size: 32px;
  line-height: 1.15;
  font-weight: 800;
  text-transform: uppercase;
}

.nw-featured .nw-description {
  margin: 12px 0 0;
  font-size: 20px;
  line-height: 1.35;
}

.nw-featured .nw-dots {
  display: flex;
  justify-content: center;
  gap: 2px;
  margin: 4px 0 12px;
}

.nw-featured .nw-dot {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  border: 0;
  padding: 0;
  background: transparent;
  cursor: pointer;
}

.nw-featured .nw-dot::before {
  content: "";
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #c7c0b9;
}

.nw-featured .nw-dot[aria-pressed="true"]::before {
  background: #141311;
}

.nw-featured .nw-link {
  color: #141311;
  font-size: 16px;
  text-underline-offset: 5px;
}

.nw-featured button:focus-visible {
  outline: 3px solid #9a632e;
  outline-offset: -3px;
}

/* Consistent catalogue sizing */

.menu-page #menu-catalogue .menu-product-grid {
  align-items: start;
}

.menu-page #menu-catalogue .menu-product {
  min-width: 0;
  min-height: 0;
  height: auto;
  padding: 0 8px;
  background: transparent;
}

.menu-page #menu-catalogue .menu-product-image {
  flex: none;
  width: min(100%, 248px);
  height: 310px;
  margin: 0 auto;
  padding: 0;
  object-fit: contain;
  object-position: center bottom;
  border: 0;
  border-radius: 0;
  background: transparent;
  box-shadow: none;
  filter: drop-shadow(0 10px 8px rgb(0 0 0 / 18%));
}

.menu-page #menu-catalogue .menu-product-name {
  margin-top: 20px;
  min-height: 2.3em;
  font-size: 24px;
  line-height: 1.15;
}

.menu-page #menu-catalogue .menu-product.is-expanded .menu-product-image {
  background: transparent;
}

.menu-page #takoyaki .menu-product-image {
  width: min(100%, 300px);
  height: 210px;
}

@media (max-width: 900px) {
  .nw-featured .nw-stage {
    height: 420px;
  }

  .menu-page #menu-catalogue .menu-product-image {
    width: min(100%, 224px);
    height: 280px;
  }

  .menu-page #takoyaki .menu-product-image {
    width: min(100%, 270px);
    height: 189px;
  }
}

@media (max-width: 650px) {
  .nw-featured {
    padding: 40px 12px;
  }

  .nw-featured > h2 {
    font-size: 34px;
  }

  .nw-featured .nw-row {
    grid-template-columns: 32px minmax(0, 1fr) 32px;
    gap: 2px;
  }

  .nw-featured .nw-stage {
    height: 290px;
  }

  .nw-featured .nw-arrow {
    width: 32px;
    height: 44px;
    font-size: 25px;
  }

  .nw-featured .nw-title {
    font-size: 25px;
  }

  .nw-featured .nw-description {
    font-size: 18px;
  }

  .nw-featured .nw-caption {
    min-height: 118px;
  }

  .menu-page #menu-catalogue .menu-product {
    padding: 0;
  }

  .menu-page #menu-catalogue .menu-product-image {
    width: min(100%, 176px);
    height: 220px;
  }

  .menu-page #menu-catalogue .menu-product-name {
    margin-top: 14px;
    font-size: 17px;
  }

  .menu-page #takoyaki .menu-product-image {
    width: min(100%, 210px);
    height: 147px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .nw-featured *,
  .menu-page #menu-catalogue .menu-product-image {
    animation: none !important;
    transition: none !important;
  }
}
#===JAVASCRIPT===
(() => {
  'use strict';

  const drinks = [
    [
      'sunset',
      'Sunset Caramel Macchiato',
      'Balanced sweet and salty caramel coffee'
    ],
    [
      'moonlight',
      'Moonlight Choco Latte',
      'Dark chocolate with creamy milk'
    ],
    [
      'dreamy',
      'Dreamy Vanilla Latte',
      'Sweet and creamy vanilla coffee'
    ],
    [
      'spanish',
      'Spanish Latte',
      'Coffee with sweetened milk'
    ]
  ];

  const imagePath = id =>
    `assets/consistent-products/${id}.png`;

  function initialize() {
    // Preserve existing catalogue buttons and detail handlers.
    document.querySelectorAll(
      '#menu-catalogue .menu-product'
    ).forEach(button => {
      const image = button.querySelector(
        '.menu-product-image'
      );

      if (
        image &&
        button.id.startsWith('product-')
      ) {
        image.src = imagePath(button.id.slice(8));
        image.removeAttribute('srcset');
      }
    });

    const old = document.querySelector(
      '#menu-featured, .home-featured-carousel, .featured'
    );

    if (
      !old ||
      document.querySelector('.nw-featured')
    ) return;

    const isMenu = document.body.classList.contains(
      'menu-page'
    );

    const section = document.createElement('section');

    section.className = 'nw-featured';

    section.id =
      old.id ||
      (isMenu ? 'menu-featured' : 'menu');

    section.setAttribute(
      'aria-roledescription',
      'carousel'
    );

    section.setAttribute(
      'aria-labelledby',
      'nw-featured-title'
    );

    section.innerHTML = `
      <h2 id="nw-featured-title">Featured Drinks</h2>

      <div class="nw-row">
        <button
          type="button"
          class="nw-arrow nw-prev"
          aria-label="Previous featured drink"
        >&#10094;</button>

        <div class="nw-stage"></div>

        <button
          type="button"
          class="nw-arrow nw-next"
          aria-label="Next featured drink"
        >&#10095;</button>
      </div>

      <div
        class="nw-caption"
        aria-live="polite"
        aria-atomic="true"
      >
        <h3 class="nw-title"></h3>
        <p class="nw-description"></p>
      </div>

      <div
        class="nw-dots"
        aria-label="Choose a featured drink"
      ></div>

      <a
        class="nw-link"
        href="${isMenu ? '#menu-categories' : 'menu.html'}"
      >Our Complete Menu</a>
    `;

    // Disconnect only the old featured-carousel handlers.
    old.replaceWith(section);

    const stage = section.querySelector('.nw-stage');
    const dots = section.querySelector('.nw-dots');
    const title = section.querySelector('.nw-title');

    const description = section.querySelector(
      '.nw-description'
    );

    const motion = matchMedia(
      '(prefers-reduced-motion: reduce)'
    );

    const mod = n =>
      (n % drinks.length + drinks.length) %
      drinks.length;

    let current = 0;
    let busy = false;
    let queue = [];
    let animations = [];
    let suppressClick = false;

    function pose(slot) {
      const scale =
        slot === 0
          ? 1
          : Math.abs(slot) === 1
            ? 0.68
            : 0.5;

      return {
        transform:
          `translate(-50%, -50%) ` +
          `translateX(${slot * stage.clientWidth * 0.355}px) ` +
          `scale(${scale})`,

        opacity: Math.abs(slot) > 1 ? 0 : 1
      };
    }

    function assign(item) {
      const [id, name] = drinks[
        mod(current + item.slot)
      ];

      const hidden = Math.abs(item.slot) > 1;

      item.button.tabIndex = hidden ? -1 : 0;

      item.button.setAttribute(
        'aria-hidden',
        String(hidden)
      );

      item.button.setAttribute(
        'aria-label',
        item.slot === 0
          ? `View ${name} on the menu`
          : `Show ${name}`
      );

      item.button.style.pointerEvents =
        hidden ? 'none' : 'auto';

      item.button.style.zIndex =
        item.slot === 0 ? '3' : '1';

      if (item.id !== id) {
        item.id = id;
        item.image.src = imagePath(id);
      }
    }

    function scrollToProduct(id) {
      const target = document.getElementById(
        `product-${id}`
      );

      if (!target) return;

      if (
        target.getAttribute('aria-expanded') !== 'true'
      ) {
        target.click();
      }

      target.focus({ preventScroll: true });

      const offset =
        (
          document.getElementById(
            'menu-categories'
          )?.getBoundingClientRect().height || 0
        ) + 16;

      window.scrollTo({
        top: Math.max(
          0,
          scrollY +
            target.getBoundingClientRect().top -
            offset
        ),
        behavior: motion.matches ? 'instant' : 'smooth'
      });
    }

    const items = [-2, -1, 0, 1, 2].map(slot => {
      const button = document.createElement('button');

      button.type = 'button';
      button.className = 'nw-item';

      const image = document.createElement('img');

      image.alt = '';
      image.draggable = false;
      image.width = 480;
      image.height = 600;

      button.append(image);
      stage.append(button);

      const item = {
        button,
        image,
        slot,
        id: null
      };

      assign(item);

      button.addEventListener('click', () => {
        if (busy || suppressClick) return;

        if (item.slot !== 0) {
          move(Math.sign(item.slot));
          return;
        }

        if (isMenu) {
          scrollToProduct(drinks[current][0]);
        } else {
          location.assign(
            `menu.html#product-${drinks[current][0]}`
          );
        }
      });

      return item;
    });

    // Preload the four carousel images.
    drinks.forEach(([id]) => {
      const image = new Image();
      image.src = imagePath(id);
    });

    function paint() {
      items.forEach(item => {
        Object.assign(
          item.button.style,
          pose(item.slot)
        );
      });
    }

    function caption() {
      title.textContent = drinks[current][1];
      description.textContent = drinks[current][2];

      [...dots.children].forEach((dot, index) => {
        dot.setAttribute(
          'aria-pressed',
          String(index === current)
        );
      });
    }

    async function drain() {
      if (busy || !queue.length) return;

      busy = true;

      const direction = queue.shift();

      const focusItem = items.find(
        item =>
          item.button === document.activeElement
      );

      current = mod(current + direction);
      animations = [];

      items.forEach(item => {
        const from = pose(item.slot);

        let next = item.slot - direction;

        const wrapped = next < -2 || next > 2;

        if (next < -2) next = 2;
        if (next > 2) next = -2;

        item.slot = next;

        assign(item);

        const to = pose(next);

        Object.assign(item.button.style, to);

        if (
          !wrapped &&
          !motion.matches &&
          item.button.animate
        ) {
          animations.push(
            item.button.animate(
              [from, to],
              {
                duration: 650,
                easing:
                  'cubic-bezier(0.22, 0.61, 0.36, 1)'
              }
            )
          );
        }
      });

      if (
        focusItem &&
        Math.abs(focusItem.slot) > 1
      ) {
        items.find(
          item => item.slot === 0
        ).button.focus({
          preventScroll: true
        });
      }

      await Promise.all(
        animations.map(animation =>
          animation.finished.catch(() => {})
        )
      );

      paint();
      caption();

      busy = false;

      drain();
    }

    function move(direction) {
      if (queue.length < 4) {
        queue.push(direction);
        drain();
      }
    }

    function goTo(index) {
      let difference = mod(index - current);

      if (difference > drinks.length / 2) {
        difference -= drinks.length;
      }

      queue = Array(
        Math.abs(difference)
      ).fill(Math.sign(difference));

      drain();
    }

    drinks.forEach((drink, index) => {
      const dot = document.createElement('button');

      dot.type = 'button';
      dot.className = 'nw-dot';

      dot.setAttribute(
        'aria-label',
        `Show ${drink[1]}`
      );

      dot.addEventListener(
        'click',
        () => goTo(index)
      );

      dots.append(dot);
    });

    section.querySelector(
      '.nw-prev'
    ).addEventListener(
      'click',
      () => move(-1)
    );

    section.querySelector(
      '.nw-next'
    ).addEventListener(
      'click',
      () => move(1)
    );

    section.addEventListener('keydown', event => {
      if (
        !['ArrowLeft', 'ArrowRight'].includes(
          event.key
        ) ||
        event.altKey ||
        event.ctrlKey ||
        event.metaKey
      ) return;

      event.preventDefault();

      move(
        event.key === 'ArrowRight' ? 1 : -1
      );
    });

    let pointer = null;

    stage.addEventListener(
      'pointerdown',
      event => {
        if (
          event.isPrimary &&
          event.button === 0
        ) {
          pointer = {
            id: event.pointerId,
            x: event.clientX,
            y: event.clientY
          };
        }
      }
    );

    window.addEventListener(
      'pointercancel',
      () => {
        pointer = null;
      }
    );

    window.addEventListener(
      'pointerup',
      event => {
        if (
          !pointer ||
          pointer.id !== event.pointerId
        ) return;

        const dx = event.clientX - pointer.x;
        const dy = event.clientY - pointer.y;

        pointer = null;

        if (
          Math.abs(dx) < 40 ||
          Math.abs(dx) <= Math.abs(dy)
        ) return;

        suppressClick = true;

        move(dx < 0 ? 1 : -1);

        setTimeout(() => {
          suppressClick = false;
        }, 0);
      }
    );

    section.addEventListener(
      'click',
      event => {
        if (suppressClick) {
          event.preventDefault();
          event.stopImmediatePropagation();
        }
      },
      true
    );

    stage.addEventListener(
      'dragstart',
      event => event.preventDefault()
    );

    function resize() {
      animations.forEach(animation => {
        if (animation.playState === 'running') {
          try {
            animation.finish();
          } catch {}
        }
      });

      paint();
    }

    if (window.ResizeObserver) {
      new ResizeObserver(
        resize
      ).observe(stage);
    } else {
      window.addEventListener(
        'resize',
        resize
      );
    }

    motion.addEventListener(
      'change',
      resize
    );

    paint();
    caption();

    // Open the matching product when arriving from Home.
    if (
      isMenu &&
      /^#product-[a-z-]+$/.test(location.hash)
    ) {
      requestAnimationFrame(() => {
        scrollToProduct(
          location.hash.slice(9)
        );
      });
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener(
      'DOMContentLoaded',
      initialize,
      { once: true }
    );
  } else {
    initialize();
  }
})();
#===END===
