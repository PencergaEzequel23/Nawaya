(() => {
  'use strict';

  function init() {
    const cards = document.querySelectorAll(
      '#story .story-card'
    );

    if (!cards.length) return;

    // EDIT YOUR DESCRIPTIONS HERE.
    const descriptions = {
      'coffee-beans.png':
        'Crafted with 80% Arabica for smooth, aromatic flavors and ' +
        '20% Robusta for a rich body and velvety crema.',

      'fresh-coffee.png':
        'Roasted daily for a fresh aroma and rich flavor in every cup.',

      'espresso.png':
        'Communicates a strong, double-volume caffeine punch ' +
        '(approx. 60 ml / 2 oz) extracted under 9 bars of pressure.'
    };

    if (!document.getElementById('nawaya-story-hover-style')) {
      const style = document.createElement('style');
      style.id = 'nawaya-story-hover-style';

      style.textContent = `
        #story .story-card.nh-ready {
          position: relative;
          isolation: isolate;
          overflow: hidden;
          border-radius: 36px;
        }

        #story .story-card.nh-ready::after {
          content: none;
        }

        #story .story-card.nh-ready > h2 {
          z-index: 1;
          inset: auto 0 0;
          margin: 0;
          min-height: 106px;
          padding: 20px 22px;
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
          background: rgba(15, 12, 10, .48);
          -webkit-backdrop-filter: blur(12px);
          backdrop-filter: blur(12px);
          border-top: 1px solid rgba(255, 255, 255, .25);
          font-weight: 600;
        }

        #story .nh-panel {
          position: absolute;
          inset: 0;
          z-index: 2;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          gap: 26px;
          padding: 32px;
          color: white;
          text-align: center;
          background: rgba(24, 16, 12, .52);
          -webkit-backdrop-filter: blur(13px);
          backdrop-filter: blur(13px);
          box-shadow: inset 0 0 18px rgba(255, 255, 255, .32);
          border: 1px solid rgba(255, 255, 255, .3);
          border-radius: inherit;
          opacity: 0;
          visibility: hidden;
          pointer-events: none;
        }

        #story .nh-panel h3 {
          margin: 0;
          font: inherit;
          font-size: clamp(22px, 2vw, 27px);
          line-height: 1.25;
          font-weight: 600;
        }

        #story .nh-panel p {
          margin: 0;
          font-size: clamp(17px, 1.6vw, 21px);
          line-height: 1.4;
        }

        #story .nh-toggle {
          position: absolute;
          inset: 0;
          z-index: 3;
          width: 100%;
          height: 100%;
          margin: 0;
          padding: 0;
          border: 0;
          border-radius: inherit;
          background: transparent;
          color: inherit;
          cursor: pointer;
          -webkit-tap-highlight-color: transparent;
        }

        #story .nh-toggle:focus-visible {
          outline: 3px solid white;
          outline-offset: -6px;
        }

        #story .story-card.nh-open > h2 {
          opacity: 0;
        }

        #story .story-card.nh-open .nh-panel {
          opacity: 1;
          visibility: visible;
        }
      `;

      document.head.append(style);
    }

    const controls = [];

    cards.forEach((card, index) => {
      if (card.classList.contains('nh-ready')) return;

      const image = card.querySelector('img');
      const heading = card.querySelector('h2');

      if (!image || !heading) return;

      const filename = image.getAttribute('src')
        .split(/[?#]/)[0]
        .split('/')
        .pop()
        .toLowerCase();

      const description = descriptions[filename];

      if (!description) return;

      const title = heading.textContent.trim();
      const panel = document.createElement('div');
      const panelTitle = document.createElement('h3');
      const paragraph = document.createElement('p');
      const button = document.createElement('button');

      panel.className = 'nh-panel';
      panel.id = `nawaya-story-panel-${index}`;
      panelTitle.id = `nawaya-story-title-${index}`;

      panelTitle.textContent = title;
      paragraph.textContent = description;

      panel.setAttribute('role', 'region');
      panel.setAttribute('aria-labelledby', panelTitle.id);
      panel.setAttribute('aria-hidden', 'true');
      panel.append(panelTitle, paragraph);

      button.type = 'button';
      button.className = 'nh-toggle';
      button.setAttribute('aria-controls', panel.id);
      button.setAttribute('aria-expanded', 'false');
      button.setAttribute('aria-label', `Show details: ${title}`);

      function setOpen(open) {
        card.classList.toggle('nh-open', open);
        button.setAttribute('aria-expanded', String(open));
        button.setAttribute(
          'aria-label',
          `${open ? 'Hide' : 'Show'} details: ${title}`
        );
        panel.setAttribute('aria-hidden', String(!open));
      }

      controls.push({ card, setOpen });

      card.addEventListener('pointerenter', event => {
        if (
          event.pointerType === 'mouse' ||
          event.pointerType === 'pen'
        ) {
          setOpen(true);
        }
      });

      card.addEventListener('pointerleave', event => {
        if (event.pointerType !== 'touch') setOpen(false);
      });

      button.addEventListener('focus', () => {
        if (button.matches(':focus-visible')) setOpen(true);
      });

      card.addEventListener('focusout', event => {
        if (!card.contains(event.relatedTarget)) setOpen(false);
      });

      button.addEventListener('click', () => {
        setOpen(button.getAttribute('aria-expanded') !== 'true');
      });

      card.append(panel, button);
      card.classList.add('nh-ready');
    });

    document.addEventListener('click', event => {
      controls.forEach(({ card, setOpen }) => {
        if (!card.contains(event.target)) setOpen(false);
      });
    });

    document.addEventListener('keydown', event => {
      if (event.key === 'Escape') {
        controls.forEach(({ setOpen }) => setOpen(false));
      }
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