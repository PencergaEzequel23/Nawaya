(() => {
  'use strict';

  const cups = {"sunset":{"w":374,"t":123,"b":535,"h":667},"dreamy":{"w":500,"t":61,"b":444,"h":500},"moonlight":{"w":407,"t":90,"b":524,"h":576},"spanish":{"w":394,"t":61,"b":608,"h":633}};

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

      const offset = /* nw-sticky-offset */ (document.querySelector(".site-header")?.getBoundingClientRect().height || 0) + ((
          document.getElementById(
            'menu-categories'
          )?.getBoundingClientRect().height || 0
        ) + 16);

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