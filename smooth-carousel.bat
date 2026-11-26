@echo off
setlocal
set "NAWAYA_CAROUSEL_INSTALLER=%~f0"

powershell.exe -NoProfile -Command "$text=[IO.File]::ReadAllText($env:NAWAYA_CAROUSEL_INSTALLER);$parts=[regex]::Split($text,'(?m)^# BEGIN_POWERSHELL\r?$');if($parts.Length -ne 2){throw 'Could not read updater.'};& ([scriptblock]::Create($parts[1]))"

set "RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %RESULT%

# BEGIN_POWERSHELL
$ErrorActionPreference = "Stop"

try {
    $folder = Split-Path -LiteralPath $env:NAWAYA_CAROUSEL_INSTALLER
    $htmlPath = Join-Path $folder "menu.html"
    $jsPath = Join-Path $folder "menu-smooth-carousel.js"

    if (!(Test-Path -LiteralPath $htmlPath)) {
        throw "menu.html not found. Put this updater beside menu.html."
    }

    $html = [IO.File]::ReadAllText($htmlPath)

    if ($html -notmatch '(?i)</head>') {
        throw "Could not find the closing head tag in menu.html."
    }

    if ($html -notmatch 'menu-featured') {
        throw "This updater needs the menu.html version I provided earlier."
    }

    $backup = Join-Path $folder (
        "backup-carousel-" + (Get-Date -Format "yyyyMMdd-HHmmss-fff")
    )

    New-Item -ItemType Directory -Path $backup | Out-Null

    Copy-Item -LiteralPath $htmlPath -Destination (
        Join-Path $backup "menu.html"
    )

    if (Test-Path -LiteralPath $jsPath) {
        Copy-Item -LiteralPath $jsPath -Destination (
            Join-Path $backup "menu-smooth-carousel.js"
        )
    }

    $javascript = @'
(() => {
  "use strict";

  const original = document.querySelector("#menu-featured");

  if (
    !original ||
    original.dataset.smoothCarousel === "true"
  ) return;

  /*
   * Replace only the featured section's old event handlers.
   * The rest of menu.js and the product catalogue stay untouched.
   */
  const section = original.cloneNode(true);
  section.dataset.smoothCarousel = "true";
  original.replaceWith(section);

  const stage = section.querySelector("#menu-featured-stage");
  const dots = section.querySelector("#menu-featured-dots");
  const title = section.querySelector("#menu-featured-name");
  const description = section.querySelector(
    "#menu-featured-description"
  );
  const previous = section.querySelector("#menu-featured-prev");
  const next = section.querySelector("#menu-featured-next");

  if (
    ![
      stage,
      dots,
      title,
      description,
      previous,
      next
    ].every(Boolean)
  ) return;

  const drinks = [
    [
      "sunset",
      "Sunset Caramel Macchiato",
      "Balanced sweet and salty caramel coffee"
    ],
    [
      "moonlight",
      "Moonlight Choco Latte",
      "Dark chocolate with creamy milk"
    ],
    [
      "dreamy",
      "Dreamy Vanilla Latte",
      "Sweet and creamy vanilla coffee"
    ],
    [
      "spanish",
      "Spanish Latte",
      "Coffee with sweetened milk"
    ]
  ];

  const motion = matchMedia(
    "(prefers-reduced-motion: reduce)"
  );

  const mod = number =>
    (
      number % drinks.length +
      drinks.length
    ) % drinks.length;

  let current = 0;
  let busy = false;
  let queue = [];
  let animations = [];
  let suppressClick = false;

  /* Settings */
  const animationDuration = 650;
  const sideScale = 0.68;
  const easing = "cubic-bezier(0.22, 0.61, 0.36, 1)";

  const style = document.createElement("style");

  style.textContent = `
    #menu-featured[data-smooth-carousel] #menu-featured-stage {
      display: block !important;
      position: relative;
      min-height: 0 !important;
      height: 540px;
      overflow: hidden;
      touch-action: pan-y;
      isolation: isolate;
    }

    #menu-featured .smooth-menu-item {
      position: absolute;
      left: 50%;
      top: 50%;
      width: 42%;
      max-width: 440px;
      height: 100%;
      margin: 0;
      padding: 8px;
      border: 0;
      border-radius: 24px;
      background: transparent;
      color: inherit;
      cursor: pointer;
      transform-origin: center;
      will-change: transform, opacity;
      animation: none !important;
      transition: none !important;
    }

    #menu-featured .smooth-menu-item img {
      display: block;
      width: 100%;
      height: 100%;
      object-fit: contain;
      pointer-events: none;
      user-select: none;
      -webkit-user-drag: none;
    }

    #menu-featured .smooth-menu-item:focus-visible {
      outline: 3px solid #b77b42;
      outline-offset: -5px;
    }

    @media (max-width: 1000px) {
      #menu-featured[data-smooth-carousel] #menu-featured-stage {
        height: 430px;
      }
    }

    @media (max-width: 650px) {
      #menu-featured[data-smooth-carousel] #menu-featured-stage {
        height: 290px;
      }

      #menu-featured .smooth-menu-item {
        padding: 2px;
      }
    }
  `;

  document.head.append(style);

  stage.replaceChildren();
  dots.replaceChildren();

  /*
   * Five persistent positions prevent visible drinks
   * from being destroyed and recreated during movement.
   */
  function pose(slot) {
    const distance = stage.clientWidth * 0.355;

    const scale =
      slot === 0
        ? 1
        : Math.abs(slot) === 1
          ? sideScale
          : 0.5;

    return {
      transform:
        `translate(-50%, -50%) ` +
        `translateX(${slot * distance}px) ` +
        `scale(${scale})`,

      opacity: Math.abs(slot) > 1 ? 0 : 1
    };
  }

  function assignProduct(item) {
    const index = mod(current + item.slot);
    const [id, name] = drinks[index];

    item.index = index;

    item.button.setAttribute(
      "aria-label",
      item.slot === 0
        ? `View ${name} in the menu`
        : `Show ${name}`
    );

    const hidden = Math.abs(item.slot) > 1;

    item.button.tabIndex = hidden ? -1 : 0;
    item.button.setAttribute(
      "aria-hidden",
      String(hidden)
    );

    item.button.style.pointerEvents =
      hidden ? "none" : "auto";

    item.button.style.zIndex =
      item.slot === 0 ? "3" : "1";

    if (item.id !== id) {
      item.id = id;

      /*
       * Prefer the solid-white versions created by
       * your previous updater. Fall back to originals.
       */
      item.image.dataset.fallback =
        `assets/menu/${id}.png`;

      item.image.src =
        `assets/menu/${id}-white.png`;
    }
  }

  function paint() {
    items.forEach(item => {
      Object.assign(
        item.button.style,
        pose(item.slot)
      );
    });
  }

  function scrollToTarget(target) {
    const bar = document.querySelector(
      "#menu-categories"
    );

    const offset =
      bar && target !== bar
        ? bar.getBoundingClientRect().height + 16
        : 0;

    window.scrollTo({
      top: Math.max(
        0,
        window.scrollY +
          target.getBoundingClientRect().top -
          offset
      ),
      behavior: motion.matches ? "instant" : "smooth"
    });
  }

  function revealProduct() {
    const button = document.getElementById(
      `product-${drinks[current][0]}`
    );

    if (!button) return;

    if (!button.classList.contains("is-expanded")) {
      button.click();
    }

    button.focus({ preventScroll: true });
    scrollToTarget(button);
  }

  const items = [-2, -1, 0, 1, 2].map(slot => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "smooth-menu-item";

    const image = document.createElement("img");
    image.alt = "";
    image.draggable = false;

    image.addEventListener("error", () => {
      const fallback = image.dataset.fallback;

      if (!fallback) return;

      delete image.dataset.fallback;
      image.src = fallback;
    });

    button.append(image);
    stage.append(button);

    const item = {
      button,
      image,
      slot,
      id: null,
      index: 0
    };

    assignProduct(item);

    button.addEventListener("click", () => {
      if (suppressClick || busy) return;

      if (item.slot === 0) {
        revealProduct();
      } else {
        requestMove(Math.sign(item.slot));
      }
    });

    return item;
  });

  function updateCaption() {
    title.textContent = drinks[current][1];
    description.textContent = drinks[current][2];

    [...dots.children].forEach((dot, index) => {
      dot.setAttribute(
        "aria-pressed",
        String(index === current)
      );
    });
  }

  async function drain() {
    if (busy || !queue.length) return;

    busy = true;

    const direction = queue.shift();
    current = mod(current + direction);

    const duration =
      motion.matches ? 0 : animationDuration;

    animations = [];

    items.forEach(item => {
      const from = pose(item.slot);

      let nextSlot = item.slot - direction;

      const wrapped =
        nextSlot < -2 || nextSlot > 2;

      if (nextSlot < -2) nextSlot = 2;
      if (nextSlot > 2) nextSlot = -2;

      item.slot = nextSlot;
      assignProduct(item);

      const to = pose(item.slot);

      Object.assign(item.button.style, to);

      /*
       * Visible items animate their position and scale.
       * Only hidden items are recycled to the other side.
       */
      if (
        !wrapped &&
        duration &&
        item.button.animate
      ) {
        const animation = item.button.animate(
          [from, to],
          {
            duration,
            easing
          }
        );

        animations.push(animation);
      }
    });

    await Promise.all(
      animations.map(animation =>
        animation.finished.catch(() => {})
      )
    );

    paint();
    updateCaption();

    busy = false;
    drain();
  }

  function requestMove(direction) {
    if (queue.length >= 4) return;

    queue.push(direction);
    drain();
  }

  function goTo(index) {
    queue = [];

    let difference = mod(index - current);

    if (difference > drinks.length / 2) {
      difference -= drinks.length;
    }

    const direction = Math.sign(difference);

    queue = Array(
      Math.abs(difference)
    ).fill(direction);

    drain();
  }

  drinks.forEach((drink, index) => {
    const button = document.createElement("button");

    button.type = "button";
    button.className = "menu-dot";

    button.setAttribute(
      "aria-label",
      `Show ${drink[1]}`
    );

    button.addEventListener("click", () => {
      goTo(index);
    });

    dots.append(button);
  });

  previous.addEventListener("click", () => {
    requestMove(-1);
  });

  next.addEventListener("click", () => {
    requestMove(1);
  });

  section.addEventListener("keydown", event => {
    if (
      !["ArrowLeft", "ArrowRight"].includes(event.key)
    ) return;

    event.preventDefault();

    requestMove(
      event.key === "ArrowRight" ? 1 : -1
    );
  });

  section.querySelectorAll(
    "[data-menu-scroll]"
  ).forEach(link => {
    link.addEventListener("click", event => {
      const id = link.getAttribute("href");

      const target = id?.startsWith("#")
        ? document.getElementById(id.slice(1))
        : null;

      if (!target) return;

      event.preventDefault();
      scrollToTarget(target);
    });
  });

  /* Swipe support */

  let pointer = null;

  stage.addEventListener("pointerdown", event => {
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
  });

  window.addEventListener("pointercancel", () => {
    pointer = null;
  });

  window.addEventListener("pointerup", event => {
    if (
      !pointer ||
      event.pointerId !== pointer.id
    ) return;

    const dx = event.clientX - pointer.x;
    const dy = event.clientY - pointer.y;

    pointer = null;

    if (
      Math.abs(dx) < 40 ||
      Math.abs(dx) <= Math.abs(dy)
    ) return;

    suppressClick = true;

    requestMove(dx < 0 ? 1 : -1);

    setTimeout(() => {
      suppressClick = false;
    }, 0);
  });

  section.addEventListener("click", event => {
    if (!suppressClick) return;

    event.preventDefault();
    event.stopImmediatePropagation();
  }, true);

  stage.addEventListener("dragstart", event => {
    event.preventDefault();
  });

  /* Responsive layout and reduced-motion support */

  function resize() {
    if (busy) {
      animations.forEach(animation => {
        try {
          animation.finish();
        } catch {}
      });
    }

    paint();
  }

  if (window.ResizeObserver) {
    new ResizeObserver(resize).observe(stage);
  } else {
    window.addEventListener("resize", resize);
  }

  motion.addEventListener("change", resize);

  paint();
  updateCaption();
})();
'@

    $tag = '<script id="nawaya-smooth-carousel" src="menu-smooth-carousel.js" defer></script>'

    if (!$html.Contains('id="nawaya-smooth-carousel"')) {
        $html = [regex]::Replace(
            $html,
            '(?i)</head>',
            "`r`n" + $tag + "`r`n</head>"
        )
    }

    $encoding = [System.Text.UTF8Encoding]::new($false)

    [IO.File]::WriteAllText(
        $jsPath,
        $javascript,
        $encoding
    )

    [IO.File]::WriteAllText(
        $htmlPath,
        $html,
        $encoding
    )

    Write-Host ""
    Write-Host "DONE! Smooth carousel motion installed." -ForegroundColor Green
    Write-Host "Drinks now grow toward the center and shrink moving away."
    Write-Host "Your original menu.js was not changed."
    Write-Host ("Backup: " + $backup)
    Write-Host ""
    Write-Host "Refresh the website with Ctrl + F5."
}
catch {
    Write-Host ""
    Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
