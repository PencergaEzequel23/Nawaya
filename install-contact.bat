
@echo off
setlocal
set "NAWAYA_CONTACT_INSTALLER=%~f0"

powershell.exe -NoProfile -Command "$text=[IO.File]::ReadAllText($env:NAWAYA_CONTACT_INSTALLER);$parts=[regex]::Split($text,'(?m)^# BEGIN_POWERSHELL\r?$');if($parts.Length -ne 2){throw 'Could not read installer.'};& ([scriptblock]::Create($parts[1]))"

set "RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %RESULT%

# BEGIN_POWERSHELL
$ErrorActionPreference = "Stop"
$exitCode = 0
$stage = $null

try {
    $folder = Split-Path -LiteralPath $env:NAWAYA_CONTACT_INSTALLER

    if (!(Test-Path -LiteralPath (Join-Path $folder "styles.css"))) {
        throw "styles.css was not found. Put this installer in your existing website folder."
    }

    if (!(Get-Command curl.exe -ErrorAction SilentlyContinue)) {
        throw "curl.exe was not found on this computer."
    }

    $encoding = [System.Text.UTF8Encoding]::new($false)

    $stage = Join-Path $folder (
        ".contact-install-" + [guid]::NewGuid().ToString("N")
    )

    New-Item -ItemType Directory -Path $stage | Out-Null

    $assets = @(
        @(
            "cart-1.png",
            "https://www.figma.com/api/mcp/asset/d0f75e2c-7841-426e-af56-ea82ea1fc279.png"
        ),
        @(
            "cart-2.png",
            "https://www.figma.com/api/mcp/asset/32bf8af0-e4e7-4ee5-99f9-ff2e0ceab162.png"
        ),
        @(
            "facebook.png",
            "https://www.figma.com/api/mcp/asset/69c91915-99f9-4c4b-9e74-72ed45dbf2bc"
        ),
        @(
            "instagram.png",
            "https://www.figma.com/api/mcp/asset/beff66c0-a7af-42a7-86fb-73fbf0ba8833"
        ),
        @(
            "tiktok.png",
            "https://www.figma.com/api/mcp/asset/e10a83a5-1851-4a20-b34b-73171843834c"
        )
    )

    Write-Host ""
    Write-Host "Downloading contact images..."

    foreach ($asset in $assets) {
        $destination = Join-Path $stage $asset[0]

        & curl.exe -fL --retry 2 --connect-timeout 20 --max-time 90 $asset[1] -o $destination

        if ($LASTEXITCODE -ne 0) {
            throw (
                "Could not download " + $asset[0] +
                ". A 403 or 404 error may mean the temporary link expired. Website pages have not been changed."
            )
        }
    }

    $html = @'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="Prepare an event enquiry for Nawaya Coffee carts.">
  <title>Contact Us | Nawaya Coffee</title>

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Afacad+Flux:wght@400;500;600;700;800&display=swap" rel="stylesheet">

  <link rel="stylesheet" href="styles.css">
  <link id="nawaya-contact-css" rel="stylesheet" href="contact.css">
  <script id="nawaya-contact-js" src="contact.js" defer></script>
</head>

<body class="contact-page">
  <header class="site-header">
    <a class="wordmark" href="index.html">Nawaya Coffee</a>
    <nav aria-label="Main navigation">
      <a href="menu.html">Menu</a>
      <a href="stores.html">Stores</a>
      <a href="index.html#story">Our Story</a>
      <a href="contact.html" aria-current="page">Contact Us</a>
    </nav>
  </header>

  <main class="contact-main">
    <section class="contact-intro" aria-labelledby="contact-title">
      <h1 id="contact-title">Book Nawaya for<br>your events!</h1>
      <p>
        Elevate your special day with a Nawaya Cart!
        Fill out the form to explore our celebration packages.
      </p>
    </section>

    <form class="contact-form" id="contact-form" novalidate>
      <div class="contact-field">
        <label for="contact-name">*Full Name</label>
        <input
          id="contact-name"
          name="name"
          type="text"
          autocomplete="name"
          placeholder="Enter Full Name"
          maxlength="200"
          required
        >
      </div>

      <div class="contact-field">
        <label for="contact-email">*Email Address</label>
        <input
          id="contact-email"
          name="email"
          type="email"
          autocomplete="email"
          placeholder="Enter Email Address"
          maxlength="254"
          required
        >
      </div>

      <div class="contact-field">
        <label for="contact-phone">*Phone Number</label>
        <input
          id="contact-phone"
          name="phone"
          type="tel"
          inputmode="tel"
          autocomplete="tel"
          placeholder="Enter Phone Number"
          maxlength="40"
          required
        >
      </div>

      <div class="contact-field">
        <label for="contact-occasion">*Occasion</label>
        <input
          id="contact-occasion"
          name="occasion"
          type="text"
          placeholder="Enter Occasion"
          maxlength="150"
          required
        >
      </div>

      <div class="contact-field">
        <label for="contact-details">*Tell us more about your event!</label>
        <textarea
          id="contact-details"
          name="details"
          placeholder="Tell us more....."
          maxlength="4000"
          rows="2"
          required
        ></textarea>
      </div>

      <div class="contact-submit-row">
        <button class="contact-pill" id="contact-send" type="submit" disabled>
          Send Message
        </button>
      </div>

      <p class="contact-form-note">
        Prepare your enquiry here, then send it through our Facebook page.
      </p>
    </form>

    <p
      class="contact-status"
      id="contact-status"
      role="status"
      aria-live="polite"
    ></p>

    <section
      class="contact-result"
      id="contact-result"
      aria-labelledby="contact-result-title"
      hidden
    >
      <h2 id="contact-result-title">Your event enquiry</h2>
      <p>This message has not been sent yet.</p>

      <textarea
        id="contact-preview"
        aria-label="Prepared event enquiry"
        rows="10"
        readonly
      ></textarea>

      <div class="contact-result-actions">
        <button class="contact-pill" id="contact-copy" type="button">
          Copy Message
        </button>

        <a
          class="contact-pill"
          href="https://www.facebook.com/profile.php?id=61585303635196"
          target="_blank"
          rel="noopener noreferrer"
        >Open Facebook to Send</a>

        <button class="contact-outline" id="contact-save" type="button">
          Save Enquiry
        </button>
      </div>
    </section>

    <noscript>
      <p class="contact-form-note">
        Enable JavaScript to prepare an enquiry, or
        <a href="https://www.facebook.com/profile.php?id=61585303635196">
          contact Nawaya Coffee on Facebook
        </a>.
      </p>
    </noscript>

    <section class="contact-carts" aria-labelledby="contact-carts-title">
      <h2 id="contact-carts-title">Nawaya Carts</h2>

      <div class="contact-cart-grid">
        <img
          src="assets/contact/cart-1.png"
          alt="Nawaya Coffee cart beneath an outdoor umbrella"
          width="357"
          height="515"
          loading="lazy"
        >
        <img
          src="assets/contact/cart-2.png"
          alt="Nawaya Coffee cart with an illuminated front sign"
          width="379"
          height="506"
          loading="lazy"
        >
      </div>
    </section>
  </main>

  <footer class="site-footer">
    <div class="footer-main">
      <a class="footer-brand" href="index.html">NAWAYA<br>COFFEE</a>

      <nav aria-label="Footer navigation">
        <a href="menu.html">Menu</a>
        <a href="stores.html">Stores</a>
        <a href="index.html#story">About Us</a>
        <a href="contact.html" aria-current="page">Contact</a>
      </nav>

      <div class="footer-news">
        <h2>NAWAYA News</h2>
        <p>Stay updated with the latest.</p>
        <a href="news.html">Read Now</a>
      </div>
    </div>

    <p class="copyright">© Nawaya Coffee all rights reserved</p>
  </footer>
</body>
</html>
'@

    $css = @'
/* Contact page styles are scoped to preserve existing pages. */

.contact-page {
  background: #141311;
  color: #fff;
}

.contact-page .site-header {
  background: #141311;
  color: #fff;
}

.contact-page .site-header a[aria-current="page"] {
  text-decoration: underline;
  text-underline-offset: 6px;
}

.contact-main {
  padding: 48px 24px 145px;
}

.contact-intro {
  text-align: center;
}

.contact-intro h1 {
  max-width: 760px;
  margin: 0 auto;
  font-size: clamp(42px, 5.56vw, 80px);
  line-height: 1.3;
  font-weight: 800;
  text-transform: uppercase;
}

.contact-intro > p {
  max-width: 567px;
  margin: 20px auto 0;
  font-size: 27px;
  line-height: 1.35;
}

.contact-form {
  max-width: 988px;
  margin: 50px auto 0;
}

.contact-field + .contact-field {
  margin-top: 20px;
}

.contact-field label {
  display: block;
  margin-bottom: 16px;
  font-size: 27px;
  line-height: 1.3;
}

.contact-field input,
.contact-field textarea,
.contact-result textarea {
  display: block;
  width: 100%;
  min-height: 88px;
  padding: 20px;
  border: 1px solid #a19b95;
  border-radius: 8px;
  background: #141311;
  color: #fff;
  font: inherit;
  font-size: 27px;
  line-height: 1.35;
  transition: border-color 500ms ease-out, box-shadow 500ms ease-out;
}

.contact-field textarea {
  height: 88px;
  resize: vertical;
}

.contact-field input::placeholder,
.contact-field textarea::placeholder {
  color: #c9c5c1;
  opacity: 1;
}

.contact-field input:focus,
.contact-field textarea:focus,
.contact-result textarea:focus {
  outline: none;
  border-color: #fff;
  box-shadow: 0 0 0 3px rgb(255 255 255 / 16%);
}

.contact-submit-row {
  margin-top: 40px;
  text-align: center;
}

.contact-page button {
  font-family: inherit;
  cursor: pointer;
}

.contact-pill,
.contact-outline {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 40px;
  padding: 7px 22px;
  border: 1px solid #fff;
  border-radius: 999px;
  font: inherit;
  font-size: 24px;
  line-height: 1.2;
  text-align: center;
  text-decoration: none;
  transition: background-color 300ms ease-out, color 300ms ease-out;
}

.contact-pill {
  background: #fff;
  color: #141311;
  font-weight: 700;
}

.contact-pill:hover {
  background: #d9d5d0;
}

.contact-outline {
  background: transparent;
  color: #fff;
}

.contact-outline:hover {
  background: #fff;
  color: #141311;
}

.contact-page button:focus-visible,
.contact-page a:focus-visible {
  outline: 3px solid #c58d53;
  outline-offset: 5px;
}

.contact-page button:disabled {
  opacity: .55;
  cursor: not-allowed;
}

.contact-form-note,
.contact-status {
  max-width: 988px;
  margin: 18px auto 0;
  font-size: 18px;
  line-height: 1.4;
  text-align: center;
  color: #d0cbc5;
}

.contact-status:empty {
  display: none;
}

.contact-page [hidden] {
  display: none !important;
}

.contact-result {
  max-width: 988px;
  margin: 30px auto 0;
  padding: 28px;
  border: 1px solid #827b74;
  border-radius: 16px;
}

.contact-result h2 {
  font-size: 32px;
}

.contact-result > p {
  margin: 8px 0 18px;
  font-size: 20px;
}

.contact-result textarea {
  min-height: 260px;
  font-size: 19px;
  resize: vertical;
}

.contact-result-actions {
  display: flex;
  justify-content: center;
  flex-wrap: wrap;
  gap: 12px;
  margin-top: 20px;
}

.contact-result-actions .contact-pill,
.contact-result-actions .contact-outline {
  font-size: 18px;
}

.contact-carts {
  margin-top: 76px;
  text-align: center;
}

.contact-carts h2 {
  font-size: 48px;
  line-height: 1.3;
  font-weight: 800;
  text-transform: uppercase;
}

.contact-cart-grid {
  display: grid;
  grid-template-columns: 357fr 379fr;
  align-items: start;
  gap: 53px;
  max-width: 789px;
  margin: 52px auto 0;
}

.contact-cart-grid img {
  display: block;
  width: 100%;
  height: auto;
  border-radius: 16px;
}

/* Shared footer repairs */

.site-footer .contact-social-links {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin-top: 24px;
}

.site-footer .contact-social-links a {
  display: grid;
  place-items: center;
  width: 38px;
  height: 38px;
}

.site-footer .contact-social-links img {
  display: block;
  width: 30px;
  height: 30px;
  object-fit: contain;
}

.site-footer .contact-social-links a:focus-visible {
  outline: 2px solid #70492d;
  outline-offset: 4px;
}

.site-footer .footer-news a {
  display: inline-block;
  margin-top: 6px;
  padding: 4px 20px;
  border-radius: 999px;
  background: #141311;
  color: #fff;
  text-decoration: none;
  transition: opacity 300ms ease-out;
}

.site-footer .footer-news a:hover,
.site-footer .footer-news a:focus-visible {
  opacity: .72;
}

@media (max-width: 650px) {
  .contact-main {
    padding: 40px 20px 70px;
  }

  .contact-intro > p {
    font-size: 22px;
  }

  .contact-form {
    margin-top: 36px;
  }

  .contact-field label {
    margin-bottom: 10px;
    font-size: 22px;
  }

  .contact-field input,
  .contact-field textarea {
    min-height: 64px;
    padding: 16px;
    font-size: 20px;
  }

  .contact-field textarea {
    height: 110px;
  }

  .contact-carts h2 {
    font-size: 36px;
  }

  .contact-cart-grid {
    gap: 20px;
    margin-top: 30px;
  }

  .contact-result {
    padding: 20px;
  }
}

@media (max-width: 420px) {
  .contact-cart-grid {
    grid-template-columns: 1fr;
    max-width: 320px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .contact-page *,
  .site-footer .footer-news a {
    transition: none !important;
  }
}
'@

    $javascript = @'
(() => {
  "use strict";

  const socials = [
    [
      "Instagram",
      "https://www.instagram.com/nawayacoffee.ph?rpxt=eHV5dW84eWtuOW5t",
      "instagram.png"
    ],
    [
      "Facebook",
      "https://www.facebook.com/profile.php?id=61585303635196",
      "facebook.png"
    ],
    [
      "TikTok",
      "https://vm.tiktok.com/ZS9yFA7ty9JEV-R3lAE/",
      "tiktok.png"
    ]
  ];

  /* Repair existing navigation without replacing its layout. */

  document.querySelectorAll(
    ".site-header a, .site-footer a"
  ).forEach(link => {
    const label = link.textContent
      .replace(/\s+/g, " ")
      .trim()
      .toLowerCase();

    const routes = {
      "contact": "contact.html",
      "contact us": "contact.html",
      "menu": "menu.html",
      "stores": "stores.html",
      "read now": "news.html"
    };

    if (routes[label]) {
      link.setAttribute("href", routes[label]);
    }
  });

  /* Reuse an existing footer social row where available. */

  document.querySelectorAll(".site-footer").forEach(footer => {
    let row = footer.querySelector(
      ".menu-social-links, .contact-social-links"
    );

    if (!row) {
      row = document.createElement("div");
      row.className = "contact-social-links";

      const copyright = footer.querySelector(".copyright");

      if (copyright && copyright.parentElement === footer) {
        footer.insertBefore(row, copyright);
      } else {
        footer.append(row);
      }
    }

    row.replaceChildren();

    socials.forEach(([name, url, file]) => {
      const link = document.createElement("a");
      link.href = url;
      link.target = "_blank";
      link.rel = "noopener noreferrer";
      link.setAttribute("aria-label", `Nawaya Coffee on ${name}`);

      const image = document.createElement("img");
      image.src = `assets/contact/${file}`;
      image.alt = "";
      image.width = 30;
      image.height = 30;

      link.append(image);
      row.append(link);
    });
  });

  /* The remaining behavior only runs on the contact page. */

  const form = document.querySelector("#contact-form");

  if (!form) return;

  const result = document.querySelector("#contact-result");
  const preview = document.querySelector("#contact-preview");
  const status = document.querySelector("#contact-status");

  const fields = [
    ...form.querySelectorAll("input, textarea")
  ];

  document.querySelector("#contact-send").disabled = false;

  fields.forEach(field => {
    field.addEventListener("input", () => {
      field.setCustomValidity("");

      if (!result.hidden) {
        result.hidden = true;
        preview.value = "";
        status.textContent =
          "Details changed. Select Send Message to prepare an updated enquiry.";
      }
    });
  });

  form.addEventListener("submit", event => {
    event.preventDefault();

    fields.forEach(field => {
      field.value = field.value.trim();
      field.setCustomValidity("");
    });

    const phone = form.elements.namedItem("phone");
    const digits = phone.value.replace(/\D/g, "");

    if (
      phone.value &&
      (digits.length < 7 || digits.length > 15)
    ) {
      phone.setCustomValidity(
        "Enter a phone number containing 7 to 15 digits."
      );
    }

    if (!form.reportValidity()) return;

    const data = new FormData(form);

    preview.value = [
      "NAWAYA CART EVENT ENQUIRY",
      "",
      `Full name: ${data.get("name")}`,
      `Email: ${data.get("email")}`,
      `Phone: ${data.get("phone")}`,
      `Occasion: ${data.get("occasion")}`,
      "",
      "Event details:",
      String(data.get("details"))
    ].join("\n");

    result.hidden = false;

    status.textContent =
      "Your message is prepared, not sent. Copy it, then open Facebook and send it to Nawaya Coffee.";

    result.scrollIntoView({
      block: "nearest",
      behavior: window.matchMedia(
        "(prefers-reduced-motion: reduce)"
      ).matches ? "instant" : "smooth"
    });
  });

  document.querySelector("#contact-copy").addEventListener(
    "click",
    async () => {
      if (!preview.value) return;

      try {
        if (!navigator.clipboard?.writeText) {
          throw new Error("Clipboard unavailable");
        }

        await navigator.clipboard.writeText(preview.value);

        status.textContent =
          "Copied. Open Facebook and paste your message to send it.";
      } catch {
        preview.focus();
        preview.select();

        let copied = false;

        try {
          copied = document.execCommand("copy");
        } catch {}

        status.textContent = copied
          ? "Copied. Open Facebook and paste your message to send it."
          : "The message is selected. Press Ctrl+C or use your device's Copy command.";
      }
    }
  );

  document.querySelector("#contact-save").addEventListener(
    "click",
    () => {
      if (!preview.value) return;

      const url = URL.createObjectURL(
        new Blob(
          [preview.value],
          { type: "text/plain;charset=utf-8" }
        )
      );

      const link = document.createElement("a");
      link.href = url;
      link.download = "nawaya-event-enquiry.txt";

      document.body.append(link);
      link.click();
      link.remove();

      setTimeout(() => URL.revokeObjectURL(url), 10000);

      status.textContent =
        "Enquiry download started. It has not been sent to Nawaya Coffee.";
    }
  );
})();
'@

    $knownPages = @(
        "index.html",
        "menu.html",
        "stores.html",
        "news.html",
        "news-1.html",
        "news-2.html",
        "news-3.html",
        "contact.html"
    )

    $backup = Join-Path $folder (
        "backup-contact-" + (Get-Date -Format "yyyyMMdd-HHmmss-fff")
    )

    New-Item -ItemType Directory -Path $backup | Out-Null

    foreach ($name in ($knownPages + @("contact.css", "contact.js"))) {
        $path = Join-Path $folder $name

        if (Test-Path -LiteralPath $path) {
            Copy-Item -LiteralPath $path -Destination (Join-Path $backup $name)
        }
    }

    $assetsPath = Join-Path $folder "assets\contact"

    New-Item -ItemType Directory -Force -Path $assetsPath | Out-Null

    foreach ($asset in $assets) {
        $existingAsset = Join-Path $assetsPath $asset[0]

        if (Test-Path -LiteralPath $existingAsset) {
            $assetBackup = Join-Path $backup "contact-assets"

            New-Item -ItemType Directory -Force -Path $assetBackup | Out-Null

            Copy-Item -LiteralPath $existingAsset -Destination (
                Join-Path $assetBackup $asset[0]
            )
        }

        Copy-Item -LiteralPath (Join-Path $stage $asset[0]) -Destination $existingAsset -Force
    }

    [IO.File]::WriteAllText(
        (Join-Path $folder "contact.html"),
        $html,
        $encoding
    )

    [IO.File]::WriteAllText(
        (Join-Path $folder "contact.css"),
        $css,
        $encoding
    )

    [IO.File]::WriteAllText(
        (Join-Path $folder "contact.js"),
        $javascript,
        $encoding
    )

    $contactAnchorPattern = '(?is)<a\b[^>]*>\s*Contact(?:\s+Us)?\s*</a>'
    $hrefPattern = '\bhref\s*=\s*(?:"[^"]*"|''[^'']*'')'

    foreach ($name in $knownPages) {
        $path = Join-Path $folder $name

        if (!(Test-Path -LiteralPath $path)) {
            continue
        }

        $page = [IO.File]::ReadAllText($path)

        if ($page -notmatch '(?i)</head>') {
            Write-Warning ("Skipped page without a closing head tag: " + $name)
            continue
        }

        $page = [regex]::Replace(
            $page,
            $contactAnchorPattern,
            [System.Text.RegularExpressions.MatchEvaluator] {
                param($match)

                if ([regex]::IsMatch($match.Value, $hrefPattern)) {
                    return [regex]::Replace(
                        $match.Value,
                        $hrefPattern,
                        'href="contact.html"'
                    )
                }

                return [regex]::Replace(
                    $match.Value,
                    '(?i)^<a\b',
                    '<a href="contact.html"'
                )
            }
        )

        $tags = ""

        if (!$page.Contains('id="nawaya-contact-css"')) {
            $tags += "`r`n" +
                '<link id="nawaya-contact-css" rel="stylesheet" href="contact.css">'
        }

        if (!$page.Contains('id="nawaya-contact-js"')) {
            $tags += "`r`n" +
                '<script id="nawaya-contact-js" src="contact.js" defer></script>'
        }

        if ($tags.Length -gt 0) {
            $page = [regex]::Replace(
                $page,
                '(?i)</head>',
                $tags + "`r`n</head>"
            )
        }

        [IO.File]::WriteAllText($path, $page, $encoding)

        Write-Host ("Updated: " + $name)
    }

    Write-Host ""
    Write-Host "DONE! Contact page and footer links installed." -ForegroundColor Green
    Write-Host ("Backups: " + $backup)
    Write-Host ""
    Write-Host "Refresh your browser with Ctrl + F5."
    Write-Host "Click Contact Us to open the new page."
    Write-Host ""
    Write-Host "The form prepares an enquiry; it does not send automatically."
}
catch {
    Write-Host ""
    Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
    $exitCode = 1
}
finally {
    if ($stage -and (Test-Path -LiteralPath $stage)) {
        Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
    }
}

exit $exitCode
