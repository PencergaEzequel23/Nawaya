(() => {
  'use strict';

  const header = document.querySelector('.site-header');
  const button = header.querySelector('.menu-toggle');
  const nav = document.getElementById('main-nav');
  const mobile = window.matchMedia('(max-width:720px)');

  function setOpen(open) {
    nav.dataset.open = String(open);
    button.setAttribute('aria-expanded', String(open));
    button.textContent = open ? 'Close menu' : 'Menu';
  }

  function sync() {
    const restoreFocus =
      !mobile.matches && document.activeElement === button;

    const hiddenFocus =
      mobile.matches && nav.contains(document.activeElement);

    setOpen(!mobile.matches);

    if (restoreFocus) nav.querySelector('a').focus();
    if (hiddenFocus) button.focus();
  }

  sync();

  button.addEventListener('click', () => {
    setOpen(nav.dataset.open !== 'true');
  });

  nav.addEventListener('click', event => {
    if (mobile.matches && event.target.closest('a')) {
      setOpen(false);
    }
  });

  document.addEventListener('keydown', event => {
    if (
      event.key === 'Escape' &&
      mobile.matches &&
      nav.dataset.open === 'true'
    ) {
      setOpen(false);
      button.focus();
    }
  });

  document.addEventListener('click', event => {
    if (mobile.matches && !header.contains(event.target)) {
      setOpen(false);
    }
  });

  if (mobile.addEventListener) {
    mobile.addEventListener('change', sync);
  } else {
    mobile.addListener(sync);
  }
})();