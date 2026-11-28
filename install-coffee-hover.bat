@echo off
setlocal
set "NAWAYA_INSTALLER=%~f0"
powershell.exe -NoLogo -NoProfile -Command "$text=[IO.File]::ReadAllText($env:NAWAYA_INSTALLER); $parts=$text -split '(?m)^:POWERSHELL_START\r?$',2; & ([scriptblock]::Create($parts[1]))"
set "RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %RESULT%

:POWERSHELL_START
$ErrorActionPreference = 'Stop'

try {
    # Compatible with Windows PowerShell 5.1.
    $root = [System.IO.Path]::GetDirectoryName(
        $env:NAWAYA_INSTALLER
    )

    $index = Join-Path $root 'index.html'
    $script = Join-Path $root 'nawaya-story-hover.js'
    $utf8 = [System.Text.UTF8Encoding]::new($false, $true)

    if (!(Test-Path -LiteralPath $index -PathType Leaf)) {
        throw 'Put this installer beside index.html, then run it again.'
    }

    $html = [IO.File]::ReadAllText($index, $utf8)

    if (!$html.Contains('story-card')) {
        throw 'No story-card section found. Nothing was changed.'
    }

    if ($html -notmatch '(?i)</body\s*>') {
        throw 'No closing body tag found. Nothing was changed.'
    }

    $js = @'
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
'@

    # Avoid duplicate installation.
    $pattern = '(?is)<script\b[^>]*\bsrc\s*=\s*["''](?:\./)?nawaya-story-hover\.js(?:\?[^"'']*)?["''][^>]*>\s*</script\s*>'
    $updated = [regex]::Replace($html, $pattern, '')

    $tag = '<script src="nawaya-story-hover.js" defer></script>'
    $bodyMatches = [regex]::Matches($updated, '(?i)</body\s*>')
    $position = $bodyMatches[$bodyMatches.Count - 1].Index
    $updated = $updated.Insert($position, $tag + "`r`n")

    # Back up everything that may be changed.
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $suffix = [guid]::NewGuid().ToString('N').Substring(0, 6)
    $backup = Join-Path $root "backup-story-hover-$stamp-$suffix"

    [IO.Directory]::CreateDirectory($backup) | Out-Null
    Copy-Item -LiteralPath $index -Destination $backup

    $hadScript = Test-Path -LiteralPath $script -PathType Leaf

    if ($hadScript) {
        Copy-Item -LiteralPath $script -Destination $backup
    }

    try {
        [IO.File]::WriteAllText($script, $js, $utf8)
        [IO.File]::WriteAllText($index, $updated, $utf8)
    }
    catch {
        Copy-Item -LiteralPath (Join-Path $backup 'index.html') `
            -Destination $index -Force

        if ($hadScript) {
            Copy-Item -LiteralPath `
                (Join-Path $backup 'nawaya-story-hover.js') `
                -Destination $script -Force
        }
        elseif (Test-Path -LiteralPath $script) {
            Remove-Item -LiteralPath $script
        }

        throw
    }

    Write-Host ''
    Write-Host 'Coffee hover installed successfully.' -ForegroundColor Green
    Write-Host 'Refresh your website with Ctrl+F5.'
    Write-Host "Backup: $backup"
    Write-Host 'To undo: restore index.html from that backup.'
    exit 0
}
catch {
    Write-Host ''
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.InvocationInfo.PositionMessage
    exit 1
}
