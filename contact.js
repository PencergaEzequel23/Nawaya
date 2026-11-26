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