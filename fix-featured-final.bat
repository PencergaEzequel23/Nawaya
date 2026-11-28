@echo off
setlocal
title Nawaya - Fixed Carousel Sizes
set "NW_SELF=%~f0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$p=[regex]::Split([IO.File]::ReadAllText($env:NW_SELF),'(?m)^#===(?:PS|CSS|JS|END)===\r?$'); & ([scriptblock]::Create($p[1]))"
set "RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %RESULT%
#===PS===
$ErrorActionPreference='Stop'
$root=Split-Path -LiteralPath $env:NW_SELF
Set-Location -LiteralPath $root
$utf8=New-Object System.Text.UTF8Encoding($false)
$backup=$null
$changed=$false

$targets=@(
  'index.html',
  'menu.html',
  'nwc-fixed.css',
  'nwc-fixed.js'
)

try {
  $p=[regex]::Split(
    [IO.File]::ReadAllText($env:NW_SELF),
    '(?m)^#===(?:PS|CSS|JS|END)===\r?$'
  )

  if($p.Count -ne 5){
    throw 'Incomplete copy. Include everything through the final END marker.'
  }

  foreach($name in @('index.html','menu.html','menu.js')){
    if(!(Test-Path -LiteralPath (Join-Path $root $name))){
      throw "Put this BAT beside index.html and menu.html. Missing: $name"
    }
  }

  Add-Type -AssemblyName System.Drawing

  $cups=@{}

  foreach($id in @('sunset','moonlight','dreamy','spanish')){
    $source=Join-Path $root "assets/transparent-products/$id.png"

    if(!(Test-Path -LiteralPath $source)){
      throw "Missing assets/transparent-products/$id.png. Use the complete project. Nothing changed."
    }

    $image=New-Object System.Drawing.Bitmap -ArgumentList $source

    try {
      $top=$image.Height
      $bottom=-1

      # Measure the cup through its central body.
      # This ignores transparent padding and side garnishes.
      foreach($fraction in @(0.48,0.50,0.52)){
        $x=[int][Math]::Floor($image.Width*$fraction)

        for($y=0;$y -lt $image.Height;$y++){
          if($image.GetPixel($x,$y).A -gt 32){
            $top=[Math]::Min($top,$y)
            $bottom=[Math]::Max($bottom,$y)
          }
        }
      }

      if($bottom-$top -lt $image.Height*0.25){
        throw "Cannot measure the cup in $id.png"
      }

      if($image.GetPixel(0,0).A -gt 32){
        throw "$id.png must have a transparent background."
      }

      $cups[$id]=@{
        w=$image.Width
        h=$image.Height
        t=$top
        b=$bottom
      }
    }
    finally {
      $image.Dispose()
    }
  }

  $js=$p[3].Trim().Replace(
    '__CUP_DATA__',
    ($cups|ConvertTo-Json -Compress -Depth 5)
  )

  $pages=@{}

  foreach($name in @('index.html','menu.html')){
    $html=[IO.File]::ReadAllText(
      (Join-Path $root $name)
    )

    if(
      $html -notmatch '(?i)</head\s*>' -or
      $html -notmatch '(?i)</body\s*>'
    ){
      throw "Missing head/body closing tag in $name"
    }

    # Keep product data and image cleanup.
    # Remove competing carousel controllers.
    $pattern='(?is)<script\b(?=[^>]*\bsrc\s*=\s*["''][^"'']*(?:home-carousel|menu-smooth-carousel|nawaya-consistent|nwc-fixed)\.js(?:\?[^"'']*)?["''])[^>]*>\s*</script\s*>'

    $html=[regex]::Replace(
      $html,
      $pattern,
      ''
    )

    $html=[regex]::Replace(
      $html,
      '(?is)<link\b(?=[^>]*\bhref\s*=\s*["''][^"'']*nwc-fixed\.css(?:\?[^"'']*)?["''])[^>]*>',
      ''
    )

    $html=[regex]::Replace(
      $html,
      '(?i)</head\s*>',
      "`r`n<link rel=`"stylesheet`" href=`"nwc-fixed.css?v=2`">`r`n</head>"
    )

    $html=[regex]::Replace(
      $html,
      '(?i)</body\s*>',
      "`r`n<script src=`"nwc-fixed.js?v=2`" defer></script>`r`n</body>"
    )

    $pages[$name]=$html
  }

  $backup=Join-Path $root (
    'backup-fixed-carousel-'+
    (Get-Date -Format 'yyyyMMdd-HHmmss')+
    '-'+
    [guid]::NewGuid().ToString('N').Substring(0,6)
  )

  [IO.Directory]::CreateDirectory($backup)|Out-Null

  $undo=@(
    '@echo off',
    'setlocal',
    'pushd "%~dp0.."',
    'if errorlevel 1 exit /b 1'
  )

  foreach($name in $targets){
    $live=Join-Path $root $name

    if(Test-Path -LiteralPath $live){
      Copy-Item `
        -LiteralPath $live `
        -Destination (Join-Path $backup $name)

      $undo+="copy /Y `"%~dp0$name`" `"$name`" >nul"
    }
    else {
      $undo+="if exist `"$name`" del /q `"$name`""
    }
  }

  $undo+=@(
    'popd',
    'echo Restored. Refresh with Ctrl+F5.',
    'pause'
  )

  [IO.File]::WriteAllText(
    (Join-Path $backup 'RESTORE.bat'),
    ($undo -join "`r`n"),
    $utf8
  )

  $changed=$true

  [IO.File]::WriteAllText(
    (Join-Path $root 'nwc-fixed.css'),
    $p[2].Trim(),
    $utf8
  )

  [IO.File]::WriteAllText(
    (Join-Path $root 'nwc-fixed.js'),
    $js,
    $utf8
  )

  foreach($name in @('index.html','menu.html')){
    [IO.File]::WriteAllText(
      (Join-Path $root $name),
      $pages[$name],
      $utf8
    )
  }

  Write-Host ''
  Write-Host 'DONE: Middle cup 100%; both side cups 56%.' -ForegroundColor Green
  Write-Host 'Applied to Home and Menu.'
  Write-Host 'Press Ctrl+F5 in your browser.'
  Write-Host "Undo: $backup\RESTORE.bat"

  exit 0
}
catch {
  $failure=$_.Exception.Message

  if($changed -and $backup){
    try {
      foreach($name in $targets){
        $live=Join-Path $root $name
        $saved=Join-Path $backup $name

        if(Test-Path -LiteralPath $saved){
          Copy-Item `
            -LiteralPath $saved `
            -Destination $live `
            -Force
        }
        elseif(Test-Path -LiteralPath $live){
          Remove-Item -LiteralPath $live -Force
        }
      }

      Write-Host 'Update cancelled; previous version restored.'
    }
    catch {
      Write-Host "Restore manually from $backup" -ForegroundColor Yellow
    }
  }

  Write-Host "ERROR: $failure" -ForegroundColor Red
  exit 1
}
#===CSS===
.nwc-featured {
  padding: 54px 24px 44px;
  background: #fff;
  color: #141311;
  text-align: center;
  overflow: hidden;
}

.nwc-featured > h2 {
  margin: 0;
  font-size: 48px;
  line-height: 1.1;
  font-weight: 800;
  text-transform: uppercase;
}

.nwc-featured .nwc-row {
  display: grid;
  grid-template-columns: 44px minmax(0, 1fr) 44px;
  align-items: center;
  gap: 12px;
  max-width: 1240px;
  margin: 24px auto 0;
}

.nwc-featured .nwc-stage {
  position: relative;
  overflow: hidden;
  touch-action: pan-y;
  isolation: isolate;
}

.nwc-featured .nwc-item {
  position: absolute;
  left: 50%;
  top: 50%;
  margin: 0;
  padding: 0;
  border: 0;
  border-radius: 0;
  background: transparent;
  cursor: pointer;
  transform-origin: center;
  animation: none !important;
  transition: none !important;
  will-change: transform, opacity;
}

.nwc-featured .nwc-item img {
  position: absolute;
  display: block;
  max-width: none !important;
  max-height: none !important;
  object-fit: fill !important;
  pointer-events: none;
  user-select: none;
  -webkit-user-drag: none;
  background: transparent;
  border: 0;
  filter: drop-shadow(0 10px 8px rgb(0 0 0 / 14%));
}

.nwc-featured .nwc-arrow {
  display: grid;
  place-items: center;
  width: 44px;
  height: 44px;
  padding: 0;
  border: 0;
  border-radius: 50%;
  background: transparent;
  color: #141311;
  font: inherit;
  font-size: 30px;
  cursor: pointer;
}

.nwc-featured .nwc-arrow:hover {
  background: #f2eeea;
}

.nwc-featured .nwc-caption {
  max-width: 760px;
  min-height: 110px;
  margin: 18px auto 0;
}

.nwc-featured .nwc-title {
  margin: 0;
  font-size: 32px;
  line-height: 1.15;
  font-weight: 800;
  text-transform: uppercase;
}

.nwc-featured .nwc-description {
  margin: 10px 0 0;
  font-size: 20px;
  line-height: 1.35;
}

.nwc-featured .nwc-symbols {
  display: flex;
  justify-content: center;
  gap: 8px;
  margin: 10px 0 0;
}

.nwc-featured .nwc-symbols img {
  width: 22px;
  height: 22px;
  object-fit: contain;
}

.nwc-featured .nwc-dots {
  display: flex;
  justify-content: center;
  gap: 2px;
  margin: 6px 0 12px;
}

.nwc-featured .nwc-dot {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  padding: 0;
  border: 0;
  background: transparent;
  cursor: pointer;
}

.nwc-featured .nwc-dot:before {
  content: "";
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #c7c0b9;
}

.nwc-featured .nwc-dot[aria-pressed="true"]:before {
  background: #141311;
}

.nwc-featured .nwc-link {
  font-size: 16px;
  color: #141311;
  text-underline-offset: 5px;
}

.nwc-featured button:focus-visible {
  outline: 3px solid #99602d;
  outline-offset: -3px;
}

@media (max-width: 650px) {
  .nwc-featured {
    padding: 36px 10px;
  }

  .nwc-featured > h2 {
    font-size: 32px;
  }

  .nwc-featured .nwc-row {
    grid-template-columns: 28px minmax(0, 1fr) 28px;
    gap: 2px;
    margin-top: 18px;
  }

  .nwc-featured .nwc-arrow {
    width: 28px;
    height: 44px;
    font-size: 24px;
  }

  .nwc-featured .nwc-title {
    font-size: 24px;
  }

  .nwc-featured .nwc-description {
    font-size: 17px;
  }

  .nwc-featured .nwc-caption {
    min-height: 112px;
    margin-top: 14px;
  }
}
#===JS===
(() => {
  'use strict';

  const cups = __CUP_DATA__;

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

  const src = id =>
    `assets/transparent-products/${id}.png`;

  async function init() {
    const old = document.querySelector(
      '#menu-featured,.featured,.home-featured-carousel,.nw-featured'
    );

    if (
      !old ||
      document.querySelector('.nwc-featured')
    ) return;

    // Load every drink before replacing the old carousel.
    await Promise.all(
      drinks.map(([id]) => new Promise((resolve, reject) => {
        const image = new Image();
        image.onload = resolve;
        image.onerror = reject;
        image.src = src(id);
      }))
    );

    const menu = document.body.classList.contains(
      'menu-page'
    );

    const section = document.createElement('section');

    section.className = 'nwc-featured';

    section.id =
      old.id ||
      (menu ? 'menu-featured' : 'menu');

    section.setAttribute(
      'aria-roledescription',
      'carousel'
    );

    section.setAttribute(
      'aria-labelledby',
      'nwc-heading'
    );

    section.innerHTML = `
      <h2 id="nwc-heading">Featured Drinks</h2>

      <div class="nwc-row">
        <button
          type="button"
          class="nwc-arrow nwc-prev"
          aria-label="Previous featured drink"
        >&#10094;</button>

        <div class="nwc-stage"></div>

        <button
          type="button"
          class="nwc-arrow nwc-next"
          aria-label="Next featured drink"
        >&#10095;</button>
      </div>

      <div
        class="nwc-caption"
        aria-live="polite"
        aria-atomic="true"
      >
        <h3 class="nwc-title"></h3>
        <p class="nwc-description"></p>
      </div>

      <div
        class="nwc-symbols"
        aria-hidden="true"
      ></div>

      <div
        class="nwc-dots"
        aria-label="Choose a featured drink"
      ></div>

      <a
        class="nwc-link"
        href="${menu ? '#menu-categories' : 'menu.html'}"
      >Our Complete Menu</a>
    `;

    old.querySelectorAll(
      '.menu-featured-symbols img'
    ).forEach(image => {
      section.querySelector(
        '.nwc-symbols'
      ).append(image.cloneNode(true));
    });

    old.replaceWith(section);

    const stage = section.querySelector('.nwc-stage');
    const dots = section.querySelector('.nwc-dots');

    const reduced = matchMedia(
      '(prefers-reduced-motion: reduce)'
    );

    const mod = n => (n % 4 + 4) % 4;

    let current = 0;
    let busy = false;
    let queue = [];
    let animations = [];
    let pointer = null;
    let suppress = false;

    function pose(slot) {
      const scale =
        slot === 0
          ? 1
          : Math.abs(slot) === 1
            ? 0.56
            : 0.36;

      return {
        transform:
          `translate(-50%,-50%) ` +
          `translateX(${slot * stage.clientWidth * 0.34}px) ` +
          `scale(${scale})`,

        opacity: Math.abs(slot) > 1 ? 0 : 1
      };
    }

    function assign(item) {
      const [id, name] = drinks[
        mod(current + item.slot)
      ];

      const c = cups[id];

      // Normalize the visible CUP height, not PNG dimensions.
      const k = 560 / (c.b - c.t + 1);

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

      if (item.id === id) return;

      item.id = id;
      item.image.src = src(id);

      // Preserve the original aspect ratio and all garnishes.
      // Each cup body occupies the same 560 reference units.
      Object.assign(item.image.style, {
        width: `${c.w * k / 600 * 100}%`,
        height: `${c.h * k / 720 * 100}%`,
        left: `${(300 - c.w * k / 2) / 600 * 100}%`,
        top: `${(80 - c.t * k) / 720 * 100}%`
      });
    }

    function reveal(id) {
      if (!menu) {
        location.assign(
          `menu.html#product-${id}`
        );
        return;
      }

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

      scrollTo({
        top: Math.max(
          0,
          scrollY +
            target.getBoundingClientRect().top -
            offset
        ),
        behavior: reduced.matches ? 'instant' : 'smooth'
      });
    }

    const items = [-2, -1, 0, 1, 2].map(slot => {
      const button = document.createElement('button');
      const image = document.createElement('img');

      button.type = 'button';
      button.className = 'nwc-item';

      image.alt = '';
      image.draggable = false;

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
        if (busy || suppress) return;

        if (item.slot === 0) {
          reveal(drinks[current][0]);
        } else {
          move(Math.sign(item.slot));
        }
      });

      return item;
    });

    function caption() {
      section.querySelector(
        '.nwc-title'
      ).textContent = drinks[current][1];

      section.querySelector(
        '.nwc-description'
      ).textContent = drinks[current][2];

      [...dots.children].forEach((dot, index) => {
        dot.setAttribute(
          'aria-pressed',
          String(index === current)
        );
      });
    }

    function paint() {
      items.forEach(item => {
        Object.assign(
          item.button.style,
          pose(item.slot)
        );
      });
    }

    function resize() {
      animations.forEach(animation => {
        if (animation.playState === 'running') {
          try {
            animation.finish();
          } catch {}
        }
      });

      const height = Math.min(
        600,
        stage.clientWidth * 0.60
      );

      stage.style.height = `${height + 24}px`;

      items.forEach(item => {
        item.button.style.height = `${height}px`;

        item.button.style.width =
          `${height * 600 / 720}px`;
      });

      paint();
    }

    async function drain() {
      if (busy || !queue.length) return;

      busy = true;

      const direction = queue.shift();

      const focused = items.find(
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
          !reduced.matches &&
          item.button.animate
        ) {
          animations.push(
            item.button.animate(
              [from, to],
              {
                duration: 600,
                easing:
                  'cubic-bezier(.22,.61,.36,1)'
              }
            )
          );
        }
      });

      if (
        focused &&
        Math.abs(focused.slot) > 1
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

    drinks.forEach((drink, index) => {
      const dot = document.createElement('button');

      dot.type = 'button';
      dot.className = 'nwc-dot';

      dot.setAttribute(
        'aria-label',
        `Show ${drink[1]}`
      );

      dot.addEventListener('click', () => {
        let difference = mod(index - current);

        if (difference > 2) {
          difference -= 4;
        }

        queue = Array(
          Math.abs(difference)
        ).fill(Math.sign(difference));

        drain();
      });

      dots.append(dot);
    });

    section.querySelector(
      '.nwc-prev'
    ).addEventListener(
      'click',
      () => move(-1)
    );

    section.querySelector(
      '.nwc-next'
    ).addEventListener(
      'click',
      () => move(1)
    );

    section.addEventListener('keydown', event => {
      if (
        !['ArrowLeft', 'ArrowRight'].includes(
          event.key
        ) ||
        event.ctrlKey ||
        event.metaKey ||
        event.altKey
      ) return;

      event.preventDefault();

      move(
        event.key === 'ArrowRight' ? 1 : -1
      );
    });

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

        suppress = true;
        move(dx < 0 ? 1 : -1);

        setTimeout(() => {
          suppress = false;
        }, 0);
      }
    );

    section.addEventListener(
      'click',
      event => {
        if (suppress) {
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

    reduced.addEventListener(
      'change',
      resize
    );

    resize();
    caption();

    if (
      menu &&
      /^#product-[a-z-]+$/.test(location.hash)
    ) {
      requestAnimationFrame(() => {
        reveal(location.hash.slice(9));
      });
    }
  }

  const start = () => {
    init().catch(error => {
      console.error(
        'Featured carousel could not initialize:',
        error
      );
    });
  };

  if (document.readyState === 'loading') {
    document.addEventListener(
      'DOMContentLoaded',
      start,
      { once: true }
    );
  } else {
    start();
  }
})();
#===END===
