(() => {
  "use strict";

  /* ========================================
     PRODUCT DATA
  ======================================== */

  const groups = [
    {
      id: "signatures",
      title: "Signatures",
      items: [
        ["sunset", "Sunset Caramel Macchiato", "Balanced sweet and salty caramel coffee"],
        ["moonlight", "Moonlight Choco Latte", "Dark chocolate with creamy milk"],
        ["dreamy", "Dreamy Vanilla Latte", "Sweet and creamy vanilla coffee"],
        ["spanish", "Spanish Latte", "Coffee with sweetened milk"]
      ]
    },
    {
      id: "iced-coffee",
      title: "Iced Coffee",
      items: [
        ["cloudy", "Cloudy Mocha", "Sweet chocolatey coffee"],
        ["pumpkin", "Pumpkin Spice", "Coffee with the flavors of pumpkin spice"],
        ["biscoff", "Dulce Biscoff Brew", "Taste of biscoff blended with coffee"],
        ["americano", "Midnight Americano", "Bold and smoky black coffee"]
      ]
    },
    {
      id: "non-coffee",
      title: "Non - Coffee",
      items: [
        ["strawberry-milk", "Strawberry Milk", "Balanced of sweet, creamy, strawberry milk"],
        ["matcha", "Matcha Serenity Latte", "Blend of earthy, sweet, and savory flavor"],
        ["oreo", "Milky Oreo", "Balanced blend of sweet milk and oreo"],
        ["matcha-berry", "Matcha - Berry Fushion", "Matcha blended with fruity strawberry"],
        ["mango", "Mango Milk Delight", "Simple goodness of mango and milk"],
        ["berry-blue", "Berry Blue Milk", "Blueberries blended with creamy milk"]
      ]
    },
    {
      id: "fruit-soda",
      title: "Fruit Soda",
      items: [
        ["lychee", "Lychee Soda", "Lychee flavored soda"],
        ["apple", "Apple Soda", "Apple flavored soda"],
        ["strawberry-soda", "Strawberry Soda", "Strawberry flavored soda"],
        ["blueberry", "Blueberry Soda", "Blueberry flavored soda"]
      ]
    },
    {
      id: "takoyaki",
      title: "Takoyaki",
      items: [
        ["cheese", "Creamy Cheese", "Crispy outside, rich melted cheese inside"],
        ["crabstick", "Flavorful Crabstick", "Savory seasoned crabstick in every bite"],
        ["ham-veggies", "Ham & Veggies", "Smoky ham with fresh, crisp veggies"],
        ["ham-cheese", "Ham & Cheese", "Savory ham with melted gooey cheese"],
        ["crabstick-veggies", "Crabstick & Veggies", "Sweet crabstick with fresh, crunchy veggies"]
      ]
    }
  ];

  /* ========================================
     PAGE ELEMENTS
  ======================================== */

  const catalogue = document.querySelector("#menu-catalogue");
  const categoryBar = document.querySelector("#menu-categories");

  const featuredSection = document.querySelector("#menu-featured");
  const stage = document.querySelector("#menu-featured-stage");
  const featureName = document.querySelector("#menu-featured-name");
  const featureDescription = document.querySelector(
    "#menu-featured-description"
  );
  const dots = document.querySelector("#menu-featured-dots");

  const previousButton = document.querySelector(
    "#menu-featured-prev"
  );
  const nextButton = document.querySelector(
    "#menu-featured-next"
  );

  const requiredElements = [
    catalogue,
    categoryBar,
    featuredSection,
    stage,
    featureName,
    featureDescription,
    dots,
    previousButton,
    nextButton
  ];

  if (requiredElements.some(element => !element)) {
    console.error(
      "Menu could not initialize. Use the matching menu.html."
    );
    return;
  }

  const products = new Map();
  const productButtons = new Map();

  const imagePath = id => `assets/menu/${id}.png`;

  const reducedMotion = window.matchMedia(
    "(prefers-reduced-motion: reduce)"
  );

  let selectedProductId = null;
  let scrollAnimation = 0;

  function createElement(tag, className, text) {
    const node = document.createElement(tag);

    if (className) {
      node.className = className;
    }

    if (text !== undefined) {
      node.textContent = text;
    }

    return node;
  }

  /* ========================================
     STICKY BAR AND INLINE DETAIL STYLES
  ======================================== */

  Object.assign(categoryBar.style, {
    position: "sticky",
    top: "0px",
    zIndex: "100",
    backgroundColor: "#141311",
    boxShadow: "0 4px 12px rgb(0 0 0 / 18%)"
  });

  let inlineStyles = document.querySelector(
    "#menu-inline-detail-styles"
  );

  if (!inlineStyles) {
    inlineStyles = document.createElement("style");
    inlineStyles.id = "menu-inline-detail-styles";
    document.head.append(inlineStyles);
  }

  inlineStyles.textContent = `
    .menu-page .menu-product-grid {
      align-items: start;
    }

    .menu-page .menu-product {
      align-self: start;
      height: auto;
    }

    .menu-page .menu-product-image {
      border-radius: 32px;
      transition:
        background-color 180ms ease-out,
        transform 180ms ease-out;
    }

    .menu-page .menu-product.is-expanded .menu-product-image {
      background-color: #fff;
      transform: none;
    }

    .menu-page .menu-inline-details {
      display: block;
      width: 100%;
      max-width: 300px;
      margin-top: 14px;
      color: #fff;
      text-align: center;
      animation: menu-inline-reveal 180ms ease-out;
    }

    .menu-page .menu-inline-description {
      display: block;
      font-size: 22px;
      line-height: 1.3;
    }

    .menu-page .menu-inline-symbols {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      margin-top: 12px;
    }

    .menu-page .menu-inline-symbols img {
      display: block;
      width: 22px;
      height: 22px;
      object-fit: contain;
    }

    @keyframes menu-inline-reveal {
      from {
        opacity: 0;
        transform: translateY(-5px);
      }

      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    @media (max-width: 650px) {
      .menu-page .menu-inline-description {
        font-size: 17px;
      }

      .menu-page .menu-product-image {
        border-radius: 24px;
      }
    }

    @media (prefers-reduced-motion: reduce) {
      .menu-page .menu-inline-details {
        animation: none;
      }
    }
  `;

  /* The old dialog is no longer used. */

  const oldDialog = document.querySelector(
    "#menu-product-dialog"
  );

  if (oldDialog && oldDialog.open) {
    oldDialog.close();
  }

  document.body.classList.remove("menu-dialog-open");

  /* ========================================
     BUILD ALL PRODUCT SECTIONS
  ======================================== */

  catalogue.replaceChildren();

  groups.forEach(group => {
    const section = createElement(
      "section",
      "menu-category"
    );

    section.id = group.id;

    section.setAttribute(
      "aria-labelledby",
      `${group.id}-title`
    );

    const heading = createElement("h2", "", group.title);
    heading.id = `${group.id}-title`;

    const grid = createElement(
      "div",
      "menu-product-grid"
    );

    group.items.forEach(([id, name, description]) => {
      products.set(id, {
        id,
        name,
        description,
        category: group.id
      });

      const button = createElement(
        "button",
        "menu-product"
      );

      button.type = "button";
      button.id = `product-${id}`;

      button.setAttribute("aria-expanded", "false");
      button.setAttribute(
        "aria-label",
        `Show ${name} details`
      );

      const image = createElement(
        "img",
        "menu-product-image"
      );

      image.src = imagePath(id);
      image.alt = "";
      image.width = 295;
      image.height = 365;
      image.loading = "lazy";

      const nameLabel = createElement(
        "span",
        "menu-product-name",
        name
      );

      button.append(image, nameLabel);

      button.addEventListener("click", () => {
        selectProduct(id);
      });

      productButtons.set(id, button);
      grid.append(button);
    });

    section.append(heading, grid);
    catalogue.append(section);
  });

  /* ========================================
     INLINE PRODUCT DETAILS — NO OVERLAY
  ======================================== */

  function closeSelectedProduct() {
    if (!selectedProductId) {
      return;
    }

    const button = productButtons.get(selectedProductId);
    const product = products.get(selectedProductId);

    if (button) {
      button.classList.remove("is-expanded");
      button.setAttribute("aria-expanded", "false");
      button.removeAttribute("aria-describedby");

      button.setAttribute(
        "aria-label",
        `Show ${product.name} details`
      );

      button.querySelector(".menu-inline-details")?.remove();
    }

    selectedProductId = null;
  }

  function selectProduct(id, scrollToProduct = false) {
    const product = products.get(id);
    const button = productButtons.get(id);

    if (!product || !button) {
      return;
    }

    if (selectedProductId === id) {
      if (scrollToProduct) {
        scrollToMenuTarget(button);
      } else {
        closeSelectedProduct();
      }

      return;
    }

    closeSelectedProduct();

    const details = createElement(
      "span",
      "menu-inline-details"
    );

    const description = createElement(
      "span",
      "menu-inline-description",
      product.description
    );

    description.id = `description-${id}`;

    const symbols = createElement(
      "span",
      "menu-inline-symbols"
    );

    symbols.setAttribute("aria-hidden", "true");

    const symbolPrefix =
      product.category === "takoyaki"
        ? "food"
        : "drink";

    for (let index = 1; index <= 2; index += 1) {
      const icon = createElement("img");

      icon.src = imagePath(
        `${symbolPrefix}-symbol-${index}`
      );

      icon.alt = "";
      symbols.append(icon);
    }

    details.append(description, symbols);
    button.append(details);

    button.classList.add("is-expanded");
    button.setAttribute("aria-expanded", "true");
    button.setAttribute(
      "aria-describedby",
      description.id
    );
    button.setAttribute(
      "aria-label",
      `Hide ${product.name} details`
    );

    selectedProductId = id;

    if (scrollToProduct) {
      requestAnimationFrame(() => {
        scrollToMenuTarget(button);
      });
    }
  }

  /* ========================================
     FEATURED CAROUSEL
  ======================================== */

  const featured = [
    "sunset",
    "moonlight",
    "dreamy",
    "spanish"
  ];

  let slide = 0;
  let suppressClick = false;

  function showSlide(nextIndex) {
    const restoreFocus = stage.contains(
      document.activeElement
    );

    slide =
      (
        nextIndex % featured.length +
        featured.length
      ) % featured.length;

    stage.replaceChildren();

    [-1, 0, 1].forEach(offset => {
      const index =
        (
          slide +
          offset +
          featured.length
        ) % featured.length;

      const id = featured[index];
      const product = products.get(id);

      const button = createElement(
        "button",
        "menu-featured-product" +
          (offset === 0 ? " is-center" : "")
      );

      button.type = "button";

      button.setAttribute(
        "aria-label",
        offset === 0
          ? `View ${product.name} in the menu`
          : `Show ${product.name}`
      );

      const image = createElement("img");

      image.src = imagePath(id);
      image.alt = "";
      image.draggable = false;

      button.append(image);

      button.addEventListener("click", () => {
        if (suppressClick) {
          return;
        }

        if (offset === 0) {
          // Open the matching product inline in the catalogue.
          selectProduct(id, true);
        } else {
          showSlide(slide + offset);
        }
      });

      stage.append(button);
    });

    const current = products.get(featured[slide]);

    featureName.textContent = current.name;
    featureDescription.textContent = current.description;

    [...dots.children].forEach((dot, index) => {
      dot.setAttribute(
        "aria-pressed",
        String(index === slide)
      );
    });

    if (restoreFocus) {
      stage.querySelector(".is-center").focus({
        preventScroll: true
      });
    }
  }

  dots.replaceChildren();

  featured.forEach((id, index) => {
    const dot = createElement("button", "menu-dot");
    dot.type = "button";

    dot.setAttribute(
      "aria-label",
      `Show ${products.get(id).name}`
    );

    dot.addEventListener("click", () => {
      showSlide(index);
    });

    dots.append(dot);
  });

  previousButton.addEventListener("click", () => {
    showSlide(slide - 1);
  });

  nextButton.addEventListener("click", () => {
    showSlide(slide + 1);
  });

  featuredSection.addEventListener("keydown", event => {
    if (
      event.key !== "ArrowLeft" &&
      event.key !== "ArrowRight"
    ) {
      return;
    }

    event.preventDefault();

    showSlide(
      slide + (event.key === "ArrowRight" ? 1 : -1)
    );
  });

  /* ========================================
     CAROUSEL SWIPE SUPPORT
  ======================================== */

  let pointerStart = null;

  stage.addEventListener("pointerdown", event => {
    if (!event.isPrimary || event.button !== 0) {
      return;
    }

    pointerStart = {
      x: event.clientX,
      y: event.clientY
    };
  });

  stage.addEventListener("pointercancel", () => {
    pointerStart = null;
  });

  stage.addEventListener("pointerup", event => {
    if (!pointerStart) {
      return;
    }

    const dx = event.clientX - pointerStart.x;
    const dy = event.clientY - pointerStart.y;

    pointerStart = null;

    if (
      Math.abs(dx) < 45 ||
      Math.abs(dx) <= Math.abs(dy)
    ) {
      return;
    }

    suppressClick = true;

    showSlide(slide + (dx < 0 ? 1 : -1));

    setTimeout(() => {
      suppressClick = false;
    }, 0);
  });

  stage.addEventListener("dragstart", event => {
    event.preventDefault();
  });

  showSlide(0);

  /* ========================================
     CATEGORY SCROLLING WITH STICKY OFFSET
  ======================================== */

  function cancelScroll() {
    cancelAnimationFrame(scrollAnimation);
    scrollAnimation = 0;
  }

  function scrollToMenuTarget(target) {
    cancelScroll();

    const start = window.scrollY;

    const stickyOffset = /* nw-sticky-offset */ (document.querySelector(".site-header")?.getBoundingClientRect().height || 0) + (target === categoryBar ? 0 : categoryBar.getBoundingClientRect().height + 16);

    const maximumScroll = Math.max(
      0,
      document.documentElement.scrollHeight -
        window.innerHeight
    );

    const destination = Math.max(
      0,
      Math.min(
        start +
          target.getBoundingClientRect().top -
          stickyOffset,
        maximumScroll
      )
    );

    if (reducedMotion.matches) {
      window.scrollTo({
        top: destination,
        behavior: "instant"
      });

      return;
    }

    const began = performance.now();
    const duration = 300;

    function animateScroll(now) {
      const progress = Math.min(
        (now - began) / duration,
        1
      );

      const easedProgress =
        1 - Math.pow(1 - progress, 3);

      window.scrollTo({
        top:
          start +
          (destination - start) * easedProgress,
        behavior: "instant"
      });

      if (progress < 1) {
        scrollAnimation =
          requestAnimationFrame(animateScroll);
      } else {
        scrollAnimation = 0;
      }
    }

    scrollAnimation =
      requestAnimationFrame(animateScroll);
  }

  document
    .querySelectorAll("[data-menu-scroll]")
    .forEach(link => {
      link.addEventListener("click", event => {
        const href = link.getAttribute("href");

        if (!href || !href.startsWith("#")) {
          return;
        }

        const target = document.getElementById(
          href.slice(1)
        );

        if (!target) {
          return;
        }

        event.preventDefault();
        scrollToMenuTarget(target);
      });
    });

  ["wheel", "touchstart", "pointerdown"].forEach(
    eventType => {
      window.addEventListener(
        eventType,
        cancelScroll,
        { passive: true }
      );
    }
  );

  window.addEventListener("keydown", event => {
    const scrollKeys = [
      "ArrowDown",
      "ArrowUp",
      "PageDown",
      "PageUp",
      "Home",
      "End",
      " "
    ];

    if (scrollKeys.includes(event.key)) {
      cancelScroll();
    }
  });

  window.addEventListener("resize", cancelScroll);
})();
