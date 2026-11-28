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