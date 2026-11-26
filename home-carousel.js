(() => {
  "use strict";

  function initialize() {
    if (document.querySelector(".home-featured-carousel")) return;

    const oldSection = document.querySelector(
      ".featured, #menu-featured"
    );

    if (!oldSection) {
      console.warn("Homepage featured-drink section was not found.");
      return;
    }

    const section = document.createElement("section");

    section.className = "home-featured-carousel";

    section.id =
      oldSection.id && oldSection.id !== "menu-featured"
        ? oldSection.id
        : "home-featured-carousel";

    section.setAttribute(
      "aria-labelledby",
      "home-featured-title"
    );

    section.setAttribute(
      "aria-roledescription",
      "carousel"
    );

    section.innerHTML = `
      <h2 id="home-featured-title">Featured Drinks</h2>

      <div class="homefc-row">
        <button
          class="homefc-arrow homefc-prev"
          type="button"
          aria-label="Previous featured drink"
        >&#10094;</button>

        <div class="homefc-stage"></div>

        <button
          class="homefc-arrow homefc-next"
          type="button"
          aria-label="Next featured drink"
        >&#10095;</button>
      </div>

      <div class="homefc-caption"
           aria-live="polite"
           aria-atomic="true">
        <h3 class="homefc-title"></h3>
        <p class="homefc-description"></p>
      </div>

      <div class="homefc-dots"
           aria-label="Choose a featured drink"></div>

      <a class="homefc-menu-link" href="menu.html">
        Our Complete Menu
      </a>
    `;

    oldSection.replaceWith(section);

    const style = document.createElement("style");

    style.textContent = `
      .home-featured-carousel {
        padding: 54px 24px 48px;
        background: #fff;
        color: #141311;
        text-align: center;
        overflow: hidden;
      }

      .home-featured-carousel > h2 {
        margin: 0;
        font-size: 48px;
        line-height: 1.1;
        font-weight: 800;
        text-transform: uppercase;
      }

      .homefc-row {
        display: grid;
        grid-template-columns: 48px minmax(0, 1fr) 48px;
        align-items: center;
        gap: 16px;
        max-width: 1240px;
        margin: 24px auto 0;
      }

      .homefc-stage {
        position: relative;
        height: 540px;
        overflow: hidden;
        touch-action: pan-y;
        isolation: isolate;
      }

      .homefc-item {
        position: absolute;
        left: 50%;
        top: 50%;
        width: 42%;
        max-width: 430px;
        height: 100%;
        margin: 0;
        padding: 8px;
        border: 0;
        background: transparent;
        cursor: pointer;
        transform-origin: center;
        will-change: transform, opacity;
      }

      .homefc-item img {
        display: block;
        width: 100%;
        height: 100%;
        object-fit: contain;
        background: transparent;
        pointer-events: none;
        user-select: none;
        -webkit-user-drag: none;
        filter:
          drop-shadow(0 15px 12px rgb(0 0 0 / 16%))
          drop-shadow(0 3px 3px rgb(0 0 0 / 8%));
      }

      .homefc-arrow {
        display: grid;
        place-items: center;
        width: 48px;
        height: 48px;
        padding: 0;
        border: 0;
        border-radius: 50%;
        background: transparent;
        color: #141311;
        font: inherit;
        font-size: 32px;
        cursor: pointer;
      }

      .homefc-arrow:hover {
        background: #f3efeb;
      }

      .homefc-caption {
        min-height: 100px;
        margin-top: 20px;
      }

      .homefc-title {
        margin: 0;
        font-size: 32px;
        line-height: 1.15;
        font-weight: 800;
        text-transform: uppercase;
      }

      .homefc-description {
        margin: 12px 0 0;
        font-size: 20px;
        line-height: 1.35;
      }

      .homefc-dots {
        display: flex;
        justify-content: center;
        gap: 2px;
        margin: 4px 0 12px;
      }

      .homefc-dot {
        display: grid;
        place-items: center;
        width: 36px;
        height: 36px;
        padding: 0;
        border: 0;
        background: transparent;
        cursor: pointer;
      }

      .homefc-dot::before {
        content: "";
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background: #c7c0b9;
      }

      .homefc-dot[aria-pressed="true"]::before {
        background: #141311;
      }

      .homefc-menu-link {
        color: #141311;
        font-size: 16px;
        text-underline-offset: 5px;
      }

      .home-featured-carousel button:focus-visible {
        outline: 3px solid #b77b42;
        outline-offset: -3px;
      }

      @media (max-width: 900px) {
        .homefc-stage {
          height: 420px;
        }
      }

      @media (max-width: 600px) {
        .home-featured-carousel {
          padding: 40px 12px;
        }

        .home-featured-carousel > h2 {
          font-size: 34px;
        }

        .homefc-row {
          grid-template-columns: 32px minmax(0, 1fr) 32px;
          gap: 2px;
        }

        .homefc-stage {
          height: 290px;
        }

        .homefc-arrow {
          width: 32px;
          height: 44px;
          font-size: 25px;
        }

        .homefc-item {
          padding: 2px;
        }

        .homefc-title {
          font-size: 25px;
        }

        .homefc-description {
          font-size: 18px;
        }
      }
    `;

    document.head.append(style);

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

    const stage = section.querySelector(".homefc-stage");
    const dots = section.querySelector(".homefc-dots");
    const title = section.querySelector(".homefc-title");
    const description = section.querySelector(
      ".homefc-description"
    );

    const reducedMotion = matchMedia(
      "(prefers-reduced-motion: reduce)"
    );

    const mod = number =>
      (number % drinks.length + drinks.length) % drinks.length;

    let current = 0;
    let busy = false;
    let queue = [];
    let animations = [];
    let suppressClick = false;

    function pose(slot) {
      const distance = stage.clientWidth * 0.355;
      const scale =
        slot === 0
          ? 1
          : Math.abs(slot) === 1
            ? 0.68
            : 0.5;

      return {
        transform:
          `translate(-50%, -50%) ` +
          `translateX(${slot * distance}px) ` +
          `scale(${scale})`,
        opacity: Math.abs(slot) > 1 ? 0 : 1
      };
    }

    function updateItem(item) {
      const index = mod(current + item.slot);
      const [id, name] = drinks[index];
      const hidden = Math.abs(item.slot) > 1;

      item.button.tabIndex = hidden ? -1 : 0;

      item.button.setAttribute(
        "aria-hidden",
        String(hidden)
      );

      item.button.setAttribute(
        "aria-label",
        item.slot === 0
          ? `Explore ${name} on the menu`
          : `Show ${name}`
      );

      item.button.style.pointerEvents =
        hidden ? "none" : "auto";

      item.button.style.zIndex =
        item.slot === 0 ? "3" : "1";

      if (item.id !== id) {
        item.id = id;
        item.image.src = `assets/home-carousel/${id}.png`;
      }
    }

    const items = [-2, -1, 0, 1, 2].map(slot => {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "homefc-item";

      const image = document.createElement("img");
      image.alt = "";
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

      updateItem(item);

      button.addEventListener("click", () => {
        if (busy || suppressClick) return;

        if (item.slot === 0) {
          window.location.assign("menu.html");
        } else {
          move(Math.sign(item.slot));
        }
      });

      return item;
    });

    function paint() {
      items.forEach(item => {
        Object.assign(
          item.button.style,
          pose(item.slot)
        );
      });
    }

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

      animations = [];

      items.forEach(item => {
        const from = pose(item.slot);

        let nextSlot = item.slot - direction;
        const wrapped = nextSlot < -2 || nextSlot > 2;

        if (nextSlot < -2) nextSlot = 2;
        if (nextSlot > 2) nextSlot = -2;

        item.slot = nextSlot;
        updateItem(item);

        const to = pose(item.slot);
        Object.assign(item.button.style, to);

        if (
          !wrapped &&
          !reducedMotion.matches &&
          item.button.animate
        ) {
          animations.push(
            item.button.animate(
              [from, to],
              {
                duration: 650,
                easing: "cubic-bezier(0.22, 0.61, 0.36, 1)"
              }
            )
          );
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

    function move(direction) {
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

      queue = Array(
        Math.abs(difference)
      ).fill(Math.sign(difference));

      drain();
    }

    drinks.forEach((drink, index) => {
      const dot = document.createElement("button");
      dot.type = "button";
      dot.className = "homefc-dot";

      dot.setAttribute(
        "aria-label",
        `Show ${drink[1]}`
      );

      dot.addEventListener("click", () => goTo(index));
      dots.append(dot);
    });

    section.querySelector(".homefc-prev").addEventListener(
      "click",
      () => move(-1)
    );

    section.querySelector(".homefc-next").addEventListener(
      "click",
      () => move(1)
    );

    section.addEventListener("keydown", event => {
      if (
        !["ArrowLeft", "ArrowRight"].includes(event.key)
      ) return;

      event.preventDefault();
      move(event.key === "ArrowRight" ? 1 : -1);
    });

    let pointer = null;

    stage.addEventListener("pointerdown", event => {
      if (event.isPrimary && event.button === 0) {
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
      if (!pointer || event.pointerId !== pointer.id) return;

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
    });

    section.addEventListener("click", event => {
      if (!suppressClick) return;

      event.preventDefault();
      event.stopImmediatePropagation();
    }, true);

    stage.addEventListener("dragstart", event => {
      event.preventDefault();
    });

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

    reducedMotion.addEventListener("change", resize);

    paint();
    updateCaption();
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