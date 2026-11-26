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