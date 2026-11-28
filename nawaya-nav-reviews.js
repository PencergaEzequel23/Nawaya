(() => {
  'use strict';

  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const mobile = matchMedia('(max-width:720px)');

  const change = (query, fn) => query.addEventListener
    ? query.addEventListener('change', fn)
    : query.addListener(fn);

  let departure = null;

  window.addEventListener('pageshow', () => {
    clearTimeout(departure);
    document.documentElement.classList.remove('nw-page-leave');
  });

  document.querySelectorAll('.nw-nav').forEach(header => {
    const button = header.querySelector('.nw-menu-toggle');
    const nav = header.querySelector('.nw-navlinks');

    function open(value) {
      nav.dataset.open = String(value);
      button.setAttribute('aria-expanded', String(value));
      button.textContent = value ? 'Close menu' : 'Menu';
    }

    function resize() {
      const focusedLink =
        mobile.matches && nav.contains(document.activeElement);

      const focusedButton =
        !mobile.matches && document.activeElement === button;

      open(!mobile.matches);

      if (focusedLink) button.focus();
      if (focusedButton) nav.querySelector('a').focus();
    }

    resize();
    change(mobile, resize);

    button.addEventListener('click', () => {
      open(nav.dataset.open !== 'true');
    });

    document.addEventListener('keydown', event => {
      if (
        event.key === 'Escape' &&
        mobile.matches &&
        nav.dataset.open === 'true'
      ) {
        open(false);
        button.focus();
      }
    });

    document.addEventListener('click', event => {
      if (mobile.matches && !header.contains(event.target)) {
        open(false);
      }
    });

    const current =
      location.pathname.split('/').pop() || 'index.html';

    header.querySelectorAll('a[data-nw-page]').forEach(link => {
      if (new URL(link.href).pathname.split('/').pop() === current) {
        link.setAttribute('aria-current', 'page');
      }
    });

    header.addEventListener('click', event => {
      const link = event.target.closest('a[data-nw-page]');

      if (
        !link ||
        event.defaultPrevented ||
        event.button !== 0 ||
        event.ctrlKey ||
        event.metaKey ||
        event.shiftKey ||
        event.altKey
      ) return;

      if (mobile.matches) open(false);

      clearTimeout(departure);
      document.documentElement.classList.remove('nw-page-leave');

      if (
        reduced.matches ||
        link.dataset.nwPage === 'instant' ||
        link.href === location.href
      ) return;

      event.preventDefault();
      document.documentElement.classList.add('nw-page-leave');

      departure = setTimeout(() => {
        try {
          location.assign(link.href);
        } catch {
          document.documentElement.classList.remove('nw-page-leave');
        }
      }, 300);
    });
  });

  const routes = {
    menu: 'menu.html',
    stores: 'stores.html',
    'our story': 'our-story.html',
    'about us': 'our-story.html',
    contact: 'contact.html',
    'contact us': 'contact.html',
    'read now': 'news.html'
  };

  document.querySelectorAll('.site-footer a').forEach(link => {
    const text = link.textContent
      .replace(/\s+/g, ' ')
      .trim()
      .toLowerCase();

    if (routes[text]) link.href = routes[text];
  });

  // Original reviewer photos, embedded for offline use.
  const photos = {
    maya:'UklGRmQDAABXRUJQVlA4IFgDAAAQDwCdASowADAAPok4lkelI6IhMdmcAKARCWYAsR6EhTFg9bvN7RHof21/OsablKAfXXeX4T/a0am4D67olGUQ761BalPgDXsML2QkJP4XuWuuQTjMBJ3pDl1LvV2tlE3F3U6iMlZzjCEwFBZwfhftvrL+wbF5dAz5mbdy5FDXlwAA/gcUf9/gLOOPpYl1D/Jt5S8v1vTC7PB82UmmZVbvAixiSOyujAunhYKBtasuxUh0OBG7I/B9fc1ECE92SvOWVktnYf88oCHRfcza5k4kaGxjArsW2En2hcFnQ9hOykvYEGUPdgoNgwa3AeFc3jcCYkdDVrSdjcc2zPr981/uXFYIcU9/hDuBL8cvX8QyqLztOPVvnItUczyJAE7YlBWNUia8hgXpKaBAUh88i3v//WGbKaxbu8pml8AK+eqdndZbY+gPcR1/yym+JqnPNj7AFIZJpVTAUNFbAfTG9AX2AVNRi9wPqs5lvwQFrkpiD+30MbkTUOhSqi1mZ/2W1x/lGyXeTss2N94+QySoey7q+j/GGgL5wps8iw4tdKzOrJheLOhBbhm16BAfsPOQORZIjp1O4whPdmZZhj+H4YxgRGzOAREDAC77S77tfaPSd3wx9q+W16yROvHcYCZi+BkMljl1NOFqcOHX//Ut/ZYHfpOUC3wP1Epzz2CxDIOt8iCnaZmAnsLnMwC43TgvfVtWCRBNSI5Qpnk+8v7sLs3ucCe3lvvl9yRlNC1hFQEGbPtHME6dhDRAcKU13J9L/JG0OkwjtlLGvN3QMd4+ScpQihkO3NZcvba3VjFbBAeKQ783VESorN3sKdfApF8BawmhwfOkNvkVenWW01ePyU6VC/soMwxEMiKPFiNi2nvPMh2NwoyMjWc6f8WJHeKE3i2EX99Kd6Ky7SPPwv+gzvLuUyINz9fQAMDkiymJT0GQRYlFXZkFcH4nmIttTfz+wUCprgRy5HZSsucOAQUbqc8+fBIWk6+SgWwsyzXaCrKP6kuH55Fhur+Xy2Kqd2WQsmXIMDNWnfRGPvsIoJMnFP/5flt8lf2id8hLCivaDEZ1gzT/wKoY+7Tnv5letZ1r4QGZvneAGq2Pf4cUEyVbrU+H6VgOAhxIbE1a0mPNAs2f25bVE+opkgAA',
    luis:'UklGRk4DAABXRUJQVlA4IEIDAADwDQCdASowADAAPo06lUelI6IhMdZsAKARiWYAnTMvgs/AXb9sMO5/ud1Qxvvsg8y/GYlmtZltfV7XCTLWgb6o9gUfsBrgdNoU2FRjnbPZ8I3HnZxnJHqld6TPGxPbQtXke6droHr0L7Agr0/bi9xZgsavGKwFnCAA/oci190G+NsucSL9Jsz1yvGH+Ydd1eOvYb0KMlbbdB+4pLuaYBnsgbPzcob/mT6q6Sm3/c4XJzs2FdqNlQ6LDdDVr2w8lP/l2w0/Ne9EWMbFbXL5Frr9KQDNlAeVDWu1RHe4LigkuiSUP6A7jMn4/qX2PyK942hqcRqbs2OTEEUYytYyQlITWrTsfXEPuv52HX2i6P4wQlNClgaNafUEsiUpIo3DfE52EyVQL//gt5BHHNP/N62EO29aYc8cDOQKjXMgrt+Yrl/spTtNfSeMwhIiq71jnaS6PL1UAknjg300XnCldjIwpx0Z0P486GH1KfkSAQpbfX8vMzpVhQq8U3naxhsywcHLAMbaGDBZ5D6g08tIJDaPZTyripOdFI3DQ6yJsqKP2sgG00UWj+med78flDpI3sQMW3v5rnB4UmyeqlWxtI8PWPG8riVk6T1Hs548C2M3/8GcQuHP8wHCsPBV0H3Cexf6nuVIiysdzIpEInfK7xK/5JbIpRmg/T+V30gaRRSzS94NS6bKahpEBZ9Nw9lK8JoAhbkcHuo2Kag0529PFMTTFAuO/uxsXtO8VibKL4L2ZuQVzrGB9tS8PWXqHuaqVbMT61WGV7H+G2wYLjXiZkWxDD9pNfVxzvpW7oWFBvQOOfsuhIB2dkg99lchkhaDEl4Kqlg5D0Sy+Qn1NSWlZF3AI1LDxVNPPfgDqn2dz+8/RXdtq6U7tqB8FdgjM4AueUxf1dH59DBOwz9pdw6crn4Voj/Hag6tK/UScVtsKO4FceIDdIUvw+P/G2SP8lYGhykuTqB9JzTf3b4uZ+XnUkU/i0zeoajKeh1IyE3xHod0DUAwtipFpL3bn+KcddVEc4zsR0gDOHXD1H30PlQm9dBm5e/134dLEz2cOf2NFe37wzgj2Mw5PPiESOPZuVJwlnhFVSAm1PQ5wJvFe1rx7AJgAAA=',
    nina:'UklGRhADAABXRUJQVlA4IAQDAACwDQCdASowADAAPo02mEelIqKhMdZsAKARiUAWo3QEyjHcFXNx58A44lgvmLBXJJ3+ZUTBvTefFuhg9HfXbW0aWXSjTFrOrs7Fn5pP/9VaYheVReDVzjH/wPKdJkVdskagBwNegi88Z4JKg/KeTcRPm6JVSq7mAP75kZYxNvQG2vwTac+hwenIdi3h9+fmwCgRFvoeErE4X8/GPrK/tTl1gZ0fTXbGJ86xxlt8C0ZpuNE1wkl31sEU19XV0FuAJIFRNF2+JPZrdCM6cF0U4kZBh1fxPkXI58kBr6J1yVbiyG05HqbkqyA2ijR1p6hnemvg+p7e+pDCxleQLGDMjV6SLgGwr/2m2e+x/nPknk5vnruk5AHg7G8TENAWxo8U5EMSEeH/Em2R8BS9o81zI3tHnH8/DA1ziklzumx5G90Lpp18M96XE3BHSX7X8nWOjfq/XRzYkrmgnRfD6vyZSKMOONnuXTiE7VjKnFVWTobAFxnz+UhA9UunVVk0M8AQrZsHfW/bYnzsiGD+Utc5NkWCXXD5THczfnUcX/sawTVfxDFqcpD5zy/KqZsaP7k6Ska+3qsbT6w80/MEyS5LtZ+YWeWeezSw1f7Zm0g4EXRVK8Bo67vynkDF6xEqFZF9gSpzBAnqf7yHElK8q/5RHEzepIXd78mQh5KmYmQpil4sI4y/ggN+3m1tQbPMg3Q9SjXgQVldmeFYwQLQll7AzGNQaB541BZ8boRSZjKv78qB77VuT4fwMImddZL2GXWXdXHySK3rTqNIsNbYayzTa0MMXQNeagIgIy0xa0Yc6xbUa0m6z9xmJ67sWBrMeMEKYg86S27Y9LKPPuuzVgg1E5PNa8Zb9SmJSUmGhRlqkpqQ9l1aDZL0kq884V+xLNuTMNgtiaVyqiufxa0cqWVZFQcIbbaNGxcM3E3nQds4Z9CldukirjclKasAVYpuLB2Jor1a3c90DcvavrcEGEk12SMGO+ukYhCSekPWS5Gn/gH8dGIa+dngnWNsPv9uASqjTqzNAAAA',
    mark:'UklGRuQCAABXRUJQVlA4INgCAAAQDQCdASowADAAPoU4lUelI6IhMdmd+KAQiWwAnTKEEKaXPw//8CPbt88i43fcH936If1MgIRRDusmWsq1BQ+9x7qyPIFsV9CFPSbirWSmT2+EyfS8rjETk61xA4UGa+bsxKr+EqN0ihoUUpnfEf/31AD9k0PwKcr/lcmwDtM4U9Hrx2ZBhDsY+21tEfeZQxn58ZzQL8Bui4jxVUJOblb8rjEfzNCPjNLSh0bv+3e6fTRJRubFlrgV1roPMDsSBbSaez4CPm5c42b7/r56LaIxXtRS2zrLv9U5TleAuTIuRMpGepbO50Pv1sxkgXzoRm23S/k1/oYyx/j1hXXmOOrc6wWr4LQ+h49ZnHopWf2ApROpW6Bx0omRPpcN2KfQQVFpdnTLpVblwxob3pjdpEUyk1jDt9Y/GuHwFfu0pnnernnWD5k04q774U7DpRSocKw63FttK5cif9ncMmwyU/trG8/dfKWVDtCyLU8Msqg9S1x7IFKMA8yxqhD3qKAVKtjBqOKMYVLjvhERXeWzY39PA+NkTGj7Ou0re+/UTGyi2nOvdd+FJCzYQyl/7bH0293H/Oi0FU3VBW92v2CYDcjteRssn93SxkxJU3B0ntS2RFjb95DcNdohWr1cYoUsszTKtFgIUUvApqqeXAslMGyZhkyr6HjMnblb50l/3Ew99Hi7GSyJJAw6q1ONyskOYtQZt4KhfJoxdzBbCvldvDj2nByhvu0tFCrRee64TrojS27hImEjB3UCtC7kOyL2+cojSSYsP0dBhzYqpKs74O67oKax85Fit7du3epuXOcLKIMf7DxyYPcAuB8+ONrDORX3ihQFbUOWGqwb5emaCnyhhSA5SYGownIYXxJdp+dxHIgeTNPzr8n/WPAhz18txSsc8+nnHSC8+4Vtzt0IJKeeLW9u2/dyy+M/aEbfHOYKoi0AYIxftYTLn9PcBmiwbfI1muBgaC2wAA==',
    bea:'UklGRmQDAABXRUJQVlA4IFgDAAAQDwCdASowADAAPok0lkelIqIhNVgKqKARCWgAqScmBFSIbbY0NvpPF9I/h59TZjmFe0P6txvnH2de2F0mNL60L6BP61Lat480yd3jliEI5KBZVnWaPDkaqud6L/wnKK3+UwJszwjTfdtHhxcew5dH/zdbpNCDp1qu2yTIUOXjgoAA/v2UdTN/z1/kr9z9/5YqCvc7whKV8B/jfc3hjva241fqLY6dGdobt1GgG/qyl8CoJ8zKgvPTIinj27gVfqw8WIZxuubx7D/z+ktF7C/kiV3/AHYjGP1oLdYn015jWHuc2NehstA1c3yRjocXPLlZfUJ8pSwen3nsouCqiTS289eG+foZgwz9gfY6uPniK8wEWtML4kL9jnBmhrGUTTxeYsATb209q9JWE0Tp80FcBjGp6Sx7IAnCklpvnFHBzkJT4cpu47lUUd3cFzQF28l4Nfzy2cGE93lPmSeX8xsGwbRoxO/bY/LWCxBnEO9+YfqQby0u30d+YzQPCbK4Ux5LHJB+YnVgk7pOa+couCck/bUeQXsnlh6ml7Ym/r3pWSEHvCvCtFRoAEDASUal016zTh+73/HfbFo3s3RP0zmtZF7a4mOVMnwvmGw5/oQgFBfeXs7l22b5jvq6FxtvoYh/BrsvSyG2Vq9CMxI6HQJNbYCfBDI3KvSiK2H297hqOn1iRlsYMwnPu77qUJ5SwXhUMmF2tC/oPzJpDiAJApXEdXMtyxzP4AVyNcM6w1Rvhd4Pp96w2N3a3FWmzUUML6PQZx/k0FZtsJMTZWlj8DNE8JOyg+Zs1ZuJO5jBjitacULC/XML3g0zvtUZQuVCw28y3BHHHYBtpAWz2mK9hQsaytoXSbcApUD2nRuEt0KcY2XxF5YRpxHS40toxIiqg9MZ1mIkC6Q6aZPQGcvCCQTwZrki8L2EQIYaSoNl9eUviqIrzKYm4SjTtR6FWZ1so7eodOE45OfeHQQhxJGpErZQemDfWe8sm1s0g/dSlncsnOu+Smq7uQWCxvTNY2jW5FyBGJnqS2q8gQSoeIEBjqIHc2rf7MYjP1DlIU12JZVUXaTvWQS31DBK7yLwRX/YCMb2r9uxg/T6CZJp3oc9mLQal/WdKln86nVRfNvhL4KNyIfx74psdaAA'
  };

  const section = document.querySelector('.reviews');
  const track = section?.querySelector('.review-track');

  if (!track || section.dataset.nwReady) return;

  const cards = [
    ...track.querySelectorAll(':scope > .review-card')
  ];

  if (!cards.length) return;

  section.dataset.nwReady = 'true';
  section.classList.add('nw-reviews');

  const rail = document.createElement('div');
  rail.className = 'nw-review-rail';

  cards.forEach(card => {
    const name = card.querySelector('h3');
    const role = card.querySelector(':scope > p');
    const quote = card.querySelector('blockquote');
    const stars = card.querySelector('.stars');

    if (!name || !role || !quote || !stars) {
      rail.append(card);
      return;
    }

    const key = name.textContent.trim()
      .split(/\s+/)[0].toLowerCase();

    const head = document.createElement('div');
    head.className = 'nw-review-head';

    const profile = document.createElement('div');
    profile.className = 'nw-review-profile';

    const person = document.createElement('div');
    person.className = 'nw-review-person';

    if (photos[key]) {
      const image = document.createElement('img');
      image.className = 'nw-review-avatar';
      image.src = 'data:image/webp;base64,' + photos[key];
      image.alt = name.textContent.trim();
      image.width = image.height = 36;
      profile.append(image);
    }

    person.append(name, role);
    profile.append(person);
    head.append(stars, profile);

    card.replaceChildren(head, quote);
    rail.append(card);
  });

  cards.forEach(card => {
    const duplicate = card.cloneNode(true);

    duplicate.setAttribute('aria-hidden', 'true');
    duplicate.removeAttribute('id');

    duplicate.querySelectorAll('[id]').forEach(node => {
      node.removeAttribute('id');
    });

    duplicate.querySelectorAll('img').forEach(image => {
      image.alt = '';
    });

    rail.append(duplicate);
  });

  track.replaceChildren(rail);
  track.id = 'nw-review-viewport';
  track.tabIndex = 0;

  track.setAttribute(
    'aria-label',
    'Customer reviews. Focus or hover to pause; scroll to read.'
  );

  const toggle = document.createElement('button');
  toggle.type = 'button';
  toggle.className = 'nw-review-toggle';
  toggle.setAttribute('aria-controls', track.id);

  let paused = reduced.matches;
  let allowMotion = false;

  function state() {
    section.dataset.nwPaused = String(paused);

    section.dataset.nwReduced = String(
      reduced.matches && !allowMotion
    );

    toggle.textContent = paused
      ? 'Play reviews'
      : 'Pause reviews';

    toggle.setAttribute('aria-pressed', String(paused));
  }

  toggle.addEventListener('click', () => {
    paused = !paused;
    if (!paused) allowMotion = true;
    state();
  });

  section.append(toggle);

  track.addEventListener('pointerdown', event => {
    if (event.pointerType === 'touch') {
      paused = true;
      state();
    }
  });

  change(reduced, () => {
    allowMotion = false;
    paused = reduced.matches;
    state();
  });

  function visibility() {
    section.dataset.nwHidden = String(document.hidden);
  }

  document.addEventListener('visibilitychange', visibility);
  visibility();

  function measure() {
    const last = cards[Math.min(4, cards.length - 1)];

    const distance = Math.max(
      1,
      last.offsetLeft - cards[0].offsetLeft - 2
    );

    rail.style.setProperty(
      '--nw-review-shift',
      distance + 'px'
    );
  }

  if (window.ResizeObserver) {
    new ResizeObserver(measure).observe(track);
  } else {
    window.addEventListener('resize', measure);
  }

  measure();
  state();
})();
/* NW-STICKY-START */
(() => {
  'use strict';

  if (window.nwStickyInstalled) return;

  const header = document.querySelector('header.site-header');
  if (!header) return;

  window.nwStickyInstalled = true;

  const bar = document.getElementById('menu-categories');
  const root = document.documentElement;

  function measure() {
    root.style.setProperty(
      '--nw-header-height',
      Math.ceil(header.getBoundingClientRect().height) + 'px'
    );

    root.style.setProperty(
      '--nw-category-height',
      (bar ? Math.ceil(bar.getBoundingClientRect().height) : 0) + 'px'
    );
  }

  function shade() {
    header.classList.toggle(
      'nw-sticky-scrolled',
      window.scrollY > 8
    );
  }

  if (window.ResizeObserver) {
    const observer = new ResizeObserver(measure);
    observer.observe(header);
    if (bar) observer.observe(bar);
  }

  window.addEventListener('resize', measure, { passive: true });
  window.addEventListener('scroll', shade, { passive: true });

  window.addEventListener('pageshow', () => {
    measure();
    shade();
  });

  if (document.fonts?.ready) {
    document.fonts.ready.then(measure);
  }

  measure();
  shade();
})();
/* NW-STICKY-END */
