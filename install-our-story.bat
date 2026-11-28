@echo off
setlocal
set "NAWAYA_INSTALLER=%~f0"
powershell.exe -NoLogo -NoProfile -Command "try { $s=[IO.File]::ReadAllText($env:NAWAYA_INSTALLER); $p=$s -split '(?m)^:POWERSHELL_START\r?$',2; & ([scriptblock]::Create($p[1])) } catch { Write-Host $_ -ForegroundColor Red; exit 1 }"
set "RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %RESULT%

:POWERSHELL_START
$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false, $true)
$root = [IO.Path]::GetDirectoryName($env:NAWAYA_INSTALLER)
$backup = $null
$originals = @{}
$attempted = New-Object 'System.Collections.Generic.List[string]'

try {
    if (!(Test-Path -LiteralPath (Join-Path $root 'index.html') -PathType Leaf)) {
        throw 'Put this installer beside your existing index.html.'
    }

    # Prefer exact story exports; otherwise use existing site images.
    # Nothing is downloaded or uploaded.
    function Pick-Image($preferred, $fallback) {
        if (Test-Path -LiteralPath (Join-Path $root $preferred) -PathType Leaf) {
            return $preferred
        }

        if (Test-Path -LiteralPath (Join-Path $root $fallback) -PathType Leaf) {
            Write-Host "Using existing image: $fallback" -ForegroundColor Yellow
            return $fallback
        }

        throw "Missing image. Add $preferred or restore $fallback, then rerun."
    }

    $hero = Pick-Image 'assets/story/hero.png' 'assets/news/news-hero.png'
    $first = Pick-Image 'assets/story/first-store.png' 'assets/stores/store-06.png'
    $branch = Pick-Image 'assets/story/first-branch.png' 'assets/stores/store-01.png'
    $map = Pick-Image 'assets/story/map.png' 'assets/stores/store-map.png'

    foreach ($asset in @(
        'assets/news/news-1.png',
        'assets/news/news-2.png',
        'assets/news/news-3.png'
    )) {
        if (!(Test-Path -LiteralPath (Join-Path $root $asset) -PathType Leaf)) {
            throw "Missing existing news image: $asset. Nothing was changed."
        }
    }

    foreach ($page in @(
        'menu.html',
        'stores.html',
        'contact.html',
        'news.html',
        'news-1.html',
        'news-2.html',
        'news-3.html'
    )) {
        if (!(Test-Path -LiteralPath (Join-Path $root $page) -PathType Leaf)) {
            throw "Missing destination: $page. Restore that page before installing."
        }
    }

    $html = @'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="Discover the story of Nawaya Coffee, our craftsmanship, and our journey from Pangasinan to branches nationwide.">
  <title>Our Story | Nawaya Coffee</title>

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Afacad+Flux:wght@400;500;600;700;800&display=swap" rel="stylesheet">

  <link rel="stylesheet" href="our-story.css">
  <script src="our-story.js" defer></script>
</head>

<body>
  <a class="skip" href="#main">Skip to content</a>

  <header class="site-header">
    <a class="wordmark" href="index.html">Nawaya Coffee</a>

    <button class="menu-toggle" type="button"
      aria-controls="main-nav" aria-expanded="false">
      Menu
    </button>

    <nav class="navlinks" id="main-nav" aria-label="Main navigation">
      <a href="menu.html">Menu</a>
      <a href="stores.html">Stores</a>
      <a href="our-story.html" aria-current="page">Our Story</a>
      <a href="contact.html">Contact Us</a>
    </nav>
  </header>

  <main id="main" tabindex="-1">
    <section class="intro" aria-labelledby="intro-title">
      <div class="intro-copy">
        <h1 id="intro-title">NAWAYA COFFEE</h1>
        <p>NAWAYA is a proudly homegrown, Filipino coffee company, making premium espresso more accessible to everyone, everywhere.</p>
      </div>

      <img src="@@HERO@@" alt="Nawaya Coffee iced drinks"
        fetchpriority="high">
    </section>

    <section class="philosophy" aria-labelledby="philosophy-title">
      <h2 id="philosophy-title">GOOD COFFEE, GOOD MOOD</h2>

      <div class="story-copy">
        <p>NAWAYA Coffee is a specialty coffee brand dedicated to crafting exceptional coffee experiences rooted in passion, quality, and intention. Built on a reverence for the art of coffee making, NAWAYA focuses on sourcing high-grade beans to create rich, balanced, and nuanced espresso profiles. Every roast is carefully curated to highlight the distinct flavors and natural character of the beans, ensuring every cup delivers a premium experience.</p>

        <p>At the heart of NAWAYA Coffee is a commitment to artisanal craftsmanship and consistency. From selecting sustainable bean origins to applying precise roasting techniques, the brand places great emphasis on detail at every stage of the process.</p>

        <p>More than just a daily beverage, NAWAYA Coffee aims to create moments of pause and connection. It brings together community, culture, and quality in a welcoming atmosphere where coffee is celebrated as an art form.</p>
      </div>
    </section>

    <section class="journey" aria-labelledby="journey-title">
      <h2 id="journey-title">OUR JOURNEY</h2>

      <ol class="timeline">
        <li>
          <div class="milestone">
            <h3>1st Store</h3>
            <p>
              <a href="stores.html#urdaneta">
                Urdaneta Bypass Road, Pangasinan
              </a>
            </p>
            <p><time datetime="2023-10">October 2023</time></p>
          </div>

          <span class="year">2023</span>

          <a class="journey-image" href="stores.html#urdaneta"
            aria-label="View the Urdaneta store">
            <img src="@@FIRST@@" alt="Nawaya Coffee Urdaneta location"
              loading="lazy">
          </a>
        </li>

        <li>
          <div class="milestone">
            <h3>1st Branch</h3>
            <p>
              <a href="stores.html#villasis">Villasis, Pangasinan</a>
            </p>
            <p><time datetime="2024-04">April 2024</time></p>
          </div>

          <span class="year">2024</span>

          <a class="journey-image" href="stores.html#villasis"
            aria-label="View the Villasis branch">
            <img src="@@BRANCH@@" alt="Nawaya Coffee Villasis location"
              loading="lazy">
          </a>
        </li>

        <li>
          <div class="milestone">
            <h3>Over 10 branches nationwide</h3>
            <p><time datetime="2026-10">October 2026</time></p>
          </div>

          <span class="year">2026</span>

          <a class="journey-image map" href="stores.html"
            aria-label="Explore all Nawaya stores">
            <img src="@@MAP@@"
              alt="Philippines map showing Nawaya Coffee store locations"
              loading="lazy">
          </a>
        </li>
      </ol>
    </section>

    <section class="news" aria-labelledby="news-title">
      <h2 id="news-title">NAWAYA NEWS</h2>
      <p class="news-subtitle">Stay up to date with the latest news</p>

      <div class="news-grid">
        <article>
          <a class="news-card" href="news-1.html">
            <img src="assets/news/news-1.png"
              alt="Nawaya Coffee Sta. Maria branch" loading="lazy">
            <h3>Nawaya Coffee Launches Sta. Maria Branch</h3>
            <time datetime="2026-10-12">October 12, 2026</time>
          </a>
        </article>

        <article>
          <a class="news-card" href="news-2.html">
            <img src="assets/news/news-2.png"
              alt="Nawaya Coffee iced drinks" loading="lazy">
            <h3>Nawaya Coffee - Lucena Rolls Out Price Hike</h3>
            <time datetime="2026-09-27">September 27, 2026</time>
          </a>
        </article>

        <article>
          <a class="news-card" href="news-3.html">
            <img src="assets/news/news-3.png"
              alt="Nawaya Coffee mobile bar at an event" loading="lazy">
            <h3>Nawaya Coffee - Lucena Opens Event Bookings</h3>
            <time datetime="2026-07-14">July 14, 2026</time>
          </a>
        </article>
      </div>
    </section>
  </main>

  <footer class="site-footer">
    <div class="footer-main">
      <a class="footer-brand" href="index.html"
        aria-label="Nawaya Coffee home">
        NAWAYA<br>COFFEE
      </a>

      <div>
        <nav class="footer-nav" aria-label="Footer navigation">
          <a href="menu.html">Menu</a>
          <a href="stores.html">Stores</a>
          <a href="our-story.html" aria-current="page">About Us</a>
          <a href="contact.html">Contact</a>
        </nav>

        <nav class="socials" aria-label="Social media">
          <a href="https://vm.tiktok.com/ZS9yFA7ty9JEV-R3lAE/"
            target="_blank" rel="noopener noreferrer"
            aria-label="TikTok, opens in a new tab">TikTok</a>

          <a href="https://www.facebook.com/profile.php?id=61585303635196"
            target="_blank" rel="noopener noreferrer"
            aria-label="Facebook, opens in a new tab">Facebook</a>

          <a href="https://www.instagram.com/nawayacoffee.ph?rpxt=eHV5dW84eWtuOW5t"
            target="_blank" rel="noopener noreferrer"
            aria-label="Instagram, opens in a new tab">Instagram</a>
        </nav>
      </div>

      <div class="footer-news">
        <h2>NAWAYA News</h2>
        <p>Stay updated with the latest.</p>
        <a class="read-now" href="news.html">Read Now</a>
      </div>
    </div>

    <p class="copyright">&copy;Nawaya Coffee all rights reserved</p>
  </footer>
</body>
</html>
'@

    $css = @'
:root {
  --dark: #141211;
  --light: #f0f0f2;
  --ink: #080808;
}
* { box-sizing: border-box; }
html { scroll-behavior: smooth; scroll-padding-top: 24px; }
body {
  margin: 0;
  background: var(--dark);
  color: var(--ink);
  font-family: "Afacad Flux", Arial, sans-serif;
}
a { color: inherit; }
img { display: block; max-width: 100%; }
h1, h2, h3, p { margin: 0; }
a:focus-visible, button:focus-visible {
  outline: 3px solid #b97839;
  outline-offset: 5px;
}
.skip {
  position: absolute;
  left: 16px;
  top: 8px;
  z-index: 10;
  padding: 12px;
  background: white;
  transform: translateY(-160%);
}
.skip:focus { transform: none; }

.site-header {
  min-height: 97px;
  padding: 24px 7.5%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 28px;
  color: white;
}
.wordmark { font-size: 24px; text-decoration: none; }
.navlinks { display: flex; align-items: center; gap: 40px; }
.navlinks a { font-size: 20px; text-decoration: none; }
.navlinks a:hover,
.navlinks [aria-current],
.footer-nav a:hover {
  text-decoration: underline;
  text-underline-offset: 7px;
}
.menu-toggle {
  display: none;
  background: transparent;
  color: white;
  border: 1px solid #777;
  border-radius: 6px;
  padding: 10px 16px;
  font: inherit;
  cursor: pointer;
}

.intro {
  margin-top: 50px;
  min-height: 684px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  align-items: center;
  background: var(--light);
  overflow: hidden;
}
.intro-copy {
  padding: 64px 40px 64px max(24px, calc((100vw - 1308px) / 2));
}
.intro h1 {
  font-size: clamp(40px, 4.5vw, 64px);
  font-weight: 800;
  line-height: 1.05;
  margin-bottom: 16px;
}
.intro p {
  max-width: 570px;
  font-size: clamp(21px, 1.9vw, 27px);
  line-height: 1.35;
}
.intro > img {
  width: 100%;
  height: 684px;
  object-fit: contain;
}

.philosophy { padding: 96px 24px; color: white; }
.philosophy h2 {
  text-align: center;
  font-size: clamp(32px, 4.5vw, 64px);
  line-height: 1.1;
  font-weight: 800;
  margin-bottom: 42px;
}
.story-copy {
  max-width: 934px;
  margin: auto;
  font-size: 27px;
  line-height: 1.4;
}
.story-copy p + p { margin-top: 32px; }

.journey {
  padding: 100px max(24px, calc((100% - 1240px) / 2)) 120px;
  background: var(--light);
}
.journey > h2 {
  text-align: center;
  font-size: clamp(44px, 6.7vw, 96px);
  line-height: 1.1;
  font-weight: 800;
}
.timeline { list-style: none; margin: 90px 0 0; padding: 0; }
.timeline li {
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 1fr) 90px minmax(0, 1fr);
  gap: 28px;
  min-height: 405px;
  padding-bottom: 80px;
}
.timeline li::before {
  content: "";
  position: absolute;
  left: 50%;
  top: 0;
  bottom: 0;
  width: 2px;
  background: #b5b5b5;
  transform: translateX(-50%);
}
.timeline li:last-child { padding-bottom: 0; min-height: 900px; }
.timeline li:last-child::before { height: 40px; bottom: auto; }
.milestone { grid-column: 1; grid-row: 1; padding-top: 64px; }
.milestone h3 {
  font-size: 48px;
  line-height: 1.12;
  margin-bottom: 28px;
  font-weight: 800;
}
.milestone p { font-size: 24px; line-height: 1.4; margin-top: 12px; }
.milestone a {
  text-decoration-thickness: 1px;
  text-underline-offset: 5px;
}
.year {
  grid-column: 2;
  grid-row: 1;
  position: relative;
  z-index: 1;
  justify-self: center;
  display: grid;
  place-items: center;
  width: 90px;
  height: 90px;
  border: 8px solid #d5d5d5;
  border-radius: 50%;
  background: #4b4b4b;
  color: white;
  font-size: 20px;
}
.journey-image {
  grid-column: 3;
  grid-row: 1;
  align-self: start;
  display: block;
  margin-top: 50px;
  border-radius: 16px;
  overflow: hidden;
}
.journey-image img {
  width: 100%;
  height: 304px;
  object-fit: cover;
}
.journey-image.map { margin-top: 45px; border-radius: 0; }
.journey-image.map img {
  height: auto;
  max-height: 860px;
  object-fit: contain;
}

.news {
  padding: 64px max(24px, calc((100% - 1240px) / 2)) 100px;
  color: white;
}
.news > h2 {
  text-align: center;
  font-size: clamp(40px, 5.6vw, 80px);
  line-height: 1.1;
  font-weight: 800;
}
.news-subtitle {
  text-align: center;
  font-size: 24px;
  margin: 22px 0 64px;
}
.news-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 64px;
}
.news-card {
  display: flex;
  flex-direction: column;
  height: 100%;
  min-height: 430px;
  padding: 22px;
  border-radius: 32px;
  background: white;
  color: var(--ink);
  text-decoration: none;
  transition: transform 160ms ease, box-shadow 160ms ease;
}
.news-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 12px 24px #0005;
}
.news-card:hover h3 {
  text-decoration: underline;
  text-underline-offset: 4px;
}
.news-card img {
  width: 100%;
  aspect-ratio: 4 / 3;
  object-fit: cover;
  border-radius: 20px;
}
.news-card h3 {
  font-size: 20px;
  line-height: 1.3;
  font-weight: 500;
  margin: 20px 0 32px;
}
.news-card time { font-size: 16px; margin-top: auto; }

.site-footer {
  margin-top: 30px;
  background: white;
  padding: 48px 7% 26px;
}
.footer-main {
  display: grid;
  grid-template-columns: 1fr 2fr 1fr;
  gap: 40px;
  align-items: start;
}
.footer-brand {
  font-size: 48px;
  font-weight: 800;
  line-height: .95;
  text-decoration: none;
}
.footer-nav, .socials {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 28px;
}
.footer-nav a { font-size: 24px; text-decoration: none; }
.socials { margin-top: 40px; gap: 24px; }
.socials a { font-size: 18px; text-underline-offset: 4px; }
.footer-news h2 { font-size: 32px; }
.footer-news p { font-size: 20px; margin: 6px 0 18px; }
.read-now {
  display: inline-block;
  padding: 7px 22px;
  background: var(--dark);
  color: white;
  border-radius: 99px;
  font-size: 22px;
  text-decoration: none;
}
.read-now:hover { background: #70492d; }
.copyright { text-align: center; font-size: 20px; margin-top: 44px; }

@media (max-width: 1050px) {
  .navlinks { gap: 24px; }
  .intro { min-height: 520px; }
  .intro > img { height: 520px; }
  .story-copy { font-size: 24px; }
  .news-grid { gap: 24px; }
  .news-card { padding: 16px; }
  .footer-main { grid-template-columns: 1fr 2fr; }
  .footer-news { grid-column: 1 / -1; text-align: center; }
  .milestone h3 { font-size: 36px; }
  .milestone p { font-size: 21px; }
  .timeline li {
    gap: 20px;
    grid-template-columns: minmax(0, 1fr) 72px minmax(0, 1fr);
  }
  .year { width: 72px; height: 72px; border-width: 6px; }
}

@media (max-width: 720px) {
  .site-header { flex-wrap: wrap; padding: 20px 6%; gap: 20px; }
  .menu-toggle { display: block; }
  .navlinks {
    flex-basis: 100%;
    flex-direction: column;
    align-items: stretch;
    gap: 0;
  }
  .navlinks a { padding: 14px 0; }
  .navlinks[data-open="false"] { display: none; }
  .intro {
    margin-top: 16px;
    grid-template-columns: 1fr;
    min-height: 0;
  }
  .intro-copy { padding: 56px 7% 24px; }
  .intro > img { height: auto; max-height: 420px; object-fit: contain; }
  .philosophy { padding: 64px 7%; }
  .story-copy { font-size: 21px; line-height: 1.5; }
  .journey { padding: 64px 7%; }
  .timeline { margin-top: 50px; }
  .timeline li {
    grid-template-columns: 66px minmax(0, 1fr);
    gap: 16px;
    min-height: 0;
    padding-bottom: 54px;
  }
  .timeline li::before { left: 33px; }
  .timeline li:last-child { min-height: 0; }
  .year {
    grid-column: 1;
    grid-row: 1;
    width: 66px;
    height: 66px;
    font-size: 17px;
  }
  .milestone { grid-column: 2; grid-row: 1; padding-top: 12px; }
  .milestone h3 { font-size: 32px; margin-bottom: 18px; }
  .milestone p { font-size: 20px; }
  .journey-image, .journey-image.map {
    grid-column: 2;
    grid-row: 2;
    margin: 12px 0 0;
  }
  .journey-image img {
    height: auto;
    aspect-ratio: 1.7;
    object-fit: cover;
  }
  .journey-image.map img { aspect-ratio: auto; max-height: 600px; }
  .news { padding: 64px 7%; }
  .news-subtitle { font-size: 21px; margin-bottom: 36px; }
  .news-grid {
    grid-template-columns: 1fr;
    gap: 28px;
    max-width: 440px;
    margin: auto;
  }
  .news-card { min-height: 0; padding: 22px; }
  .news-card h3 { font-size: 22px; }
  .footer-main { grid-template-columns: 1fr; text-align: center; }
  .footer-news { grid-column: auto; }
  .footer-nav { gap: 20px; }
  .copyright { font-size: 17px; }
}

@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  .news-card { transition: none; }
  .news-card:hover { transform: none; }
}
'@

    $js = @'
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
'@

    $html = $html.Replace('@@HERO@@', $hero)
    $html = $html.Replace('@@FIRST@@', $first)
    $html = $html.Replace('@@BRANCH@@', $branch)
    $html = $html.Replace('@@MAP@@', $map)

    $writes = [ordered]@{
        'our-story.html' = $html
        'our-story.css' = $css
        'our-story.js' = $js
    }

    # Update only Our Story / About Us anchors in headers and footers.
    # Homepage cards, carousel functionality, and other content stay intact.
    $regions = '(?is)<(?:header|footer)\b[^>]*>.*?</(?:header|footer)\s*>'
    $anchors = '(?is)<a\b[^>]*>.*?</a\s*>'
    $href = '(?is)\bhref\s*=\s*(["'']).*?\1'

    foreach ($file in (Get-ChildItem -LiteralPath $root -Filter '*.html' -File)) {
        if ($file.Name -ieq 'our-story.html') {
            continue
        }

        $old = [IO.File]::ReadAllText($file.FullName, $utf8)

        $new = [regex]::Replace(
            $old,
            $regions,
            [System.Text.RegularExpressions.MatchEvaluator]{
                param($region)

                [regex]::Replace(
                    $region.Value,
                    $anchors,
                    [System.Text.RegularExpressions.MatchEvaluator]{
                        param($anchor)

                        $label = [regex]::Replace(
                            $anchor.Value,
                            '<[^>]+>',
                            ' '
                        )

                        $label = [System.Net.WebUtility]::HtmlDecode($label)
                        $label = [regex]::Replace($label, '\s+', ' ').Trim()

                        if (
                            $label -imatch '^(Our Story|About Us)$' -and
                            $anchor.Value -match $href
                        ) {
                            return [regex]::Replace(
                                $anchor.Value,
                                $href,
                                'href="our-story.html"'
                            )
                        }

                        return $anchor.Value
                    }
                )
            }
        )

        if ($new -cne $old) {
            $writes[$file.Name] = $new
        }
    }

    # Back up everything before changing the website.
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $suffix = [guid]::NewGuid().ToString('N').Substring(0, 6)
    $backup = Join-Path $root "backup-our-story-$stamp-$suffix"

    [IO.Directory]::CreateDirectory($backup) | Out-Null
    $created = New-Object 'System.Collections.Generic.List[string]'

    foreach ($name in $writes.Keys) {
        $path = Join-Path $root $name

        if (Test-Path -LiteralPath $path -PathType Container) {
            throw "A folder already uses the name $name."
        }

        $exists = Test-Path -LiteralPath $path -PathType Leaf
        $originals[$name] = $exists

        if ($exists) {
            Copy-Item -LiteralPath $path `
                -Destination (Join-Path $backup $name)
        } else {
            $created.Add($name)
        }
    }

    [IO.File]::WriteAllText(
        (Join-Path $backup 'created-files.txt'),
        ($created -join "`r`n"),
        $utf8
    )

    foreach ($name in $writes.Keys) {
        $attempted.Add($name)

        [IO.File]::WriteAllText(
            (Join-Path $root $name),
            [string]$writes[$name],
            $utf8
        )
    }

    Write-Host ''
    Write-Host 'Our Story installed successfully.' -ForegroundColor Green
    Write-Host 'Open our-story.html or use Our Story in your website navigation.'
    Write-Host 'Refresh your browser with Ctrl+F5.'
    Write-Host "Backup: $backup"
    Write-Host 'To undo: copy backed-up HTML/CSS/JS back to the website folder.'
    Write-Host 'Then delete ONLY the new items listed in created-files.txt.'
    Write-Host 'Nothing was uploaded, committed, or pushed to GitHub.'
    exit 0
}
catch {
    $problem = $_

    # Restore attempted changes if installation fails.
    foreach ($name in $attempted) {
        $path = Join-Path $root $name

        try {
            if ($originals[$name]) {
                Copy-Item -LiteralPath (Join-Path $backup $name) `
                    -Destination $path -Force
            }
            elseif (Test-Path -LiteralPath $path -PathType Leaf) {
                Remove-Item -LiteralPath $path
            }
        }
        catch {
            Write-Host "Restore manually from backup: $name" `
                -ForegroundColor Yellow
        }
    }

    Write-Host $problem.Exception.Message -ForegroundColor Red
    Write-Host $problem.InvocationInfo.PositionMessage

    if ($backup) {
        Write-Host "Backup: $backup"
    }

    exit 1
}
