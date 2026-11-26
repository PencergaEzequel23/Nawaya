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