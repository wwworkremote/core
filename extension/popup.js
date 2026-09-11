// WWWorkRemote Popup
// Manages API URL and admin credentials in chrome.storage.local.

const DEFAULT_API = 'https://wwwr.localhost';

document.addEventListener('DOMContentLoaded', () => {
  const urlInput   = document.getElementById('api-url');
  const emailInput = document.getElementById('api-email');
  const passInput  = document.getElementById('api-password');
  const saveBtn    = document.getElementById('save-btn');
  const status     = document.getElementById('save-status');

  // Load saved values
  chrome.storage.local.get(['apiUrl', 'apiEmail', 'apiPassword'], (cfg) => {
    urlInput.value   = cfg.apiUrl   || DEFAULT_API;
    emailInput.value = cfg.apiEmail || '';
    // Never pre-fill the password field — just indicate it is set
    if (cfg.apiPassword) {
      passInput.placeholder = '(saved)';
    }
  });

  function save() {
    const rawUrl = urlInput.value.trim();
    const url    = rawUrl.replace(/\/$/, '') || DEFAULT_API;

    if (!/^https?:\/\/.+/.test(url)) {
      status.textContent = '⚠ URL must start with http:// or https://';
      status.style.color = '#ff9580';
      return;
    }

    const values = { apiUrl: url };
    if (emailInput.value.trim()) values.apiEmail = emailInput.value.trim();

    // Only overwrite password if the field has content (blank = keep existing)
    if (passInput.value) values.apiPassword = passInput.value;

    chrome.storage.local.set(values, () => {
      urlInput.value     = url;
      passInput.value    = '';
      passInput.placeholder = '(saved)';
      status.textContent = '✓ Saved';
      status.style.color = '#8aff80';
      setTimeout(() => { status.textContent = ''; }, 2500);
    });
  }

  saveBtn.addEventListener('click', save);
  [urlInput, emailInput, passInput].forEach(el => {
    el.addEventListener('keydown', e => { if (e.key === 'Enter') save(); });
  });

  // ── Scan This Page ─────────────────────────────────────────────────────
  // On-demand only: injects content.js into the current tab, once, right
  // now. Uses activeTab (temporary, gesture-scoped access to just this tab)
  // rather than any broad host permission -- nothing runs on any other site,
  // ever, unless this button is clicked on that specific tab.
  const scanBtn    = document.getElementById('scan-page-btn');
  const scanStatus = document.getElementById('scan-status');

  // Only http(s) pages are real websites -- chrome://, chrome-extension://,
  // the Chrome Web Store, file://, PDF viewers, etc. can't host job content
  // and executeScript would just fail on most of them anyway. Disabling up
  // front is clearer than letting the click happen and showing an error.
  chrome.tabs.query({ active: true, currentWindow: true }, ([tab]) => {
    if (!/^https?:\/\//.test(tab?.url || '')) {
      scanBtn.disabled = true;
      scanBtn.style.opacity = '0.4';
      scanBtn.style.cursor = 'not-allowed';
      scanStatus.textContent = 'Not available on this page';
      scanStatus.style.color = '#9590c5';
    }
  });

  scanBtn.addEventListener('click', async () => {
    scanStatus.textContent = 'Scanning…';
    scanStatus.style.color = '#9580ff';

    try {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      if (!tab?.id) throw new Error('No active tab');
      if (!/^https?:\/\//.test(tab.url || '')) throw new Error('Not a website');

      // Flag read by content.js to allow generic (non-curated-board) capture
      // for this one injection only.
      await chrome.scripting.executeScript({
        target: { tabId: tab.id },
        func: () => { window.__wwrManualScan = true; },
      });
      await chrome.scripting.executeScript({
        target: { tabId: tab.id },
        files: ['content.js'],
      });

      scanStatus.textContent = '✓ Scanning tab — check the page';
      scanStatus.style.color = '#8aff80';
      setTimeout(() => window.close(), 900);
    } catch (err) {
      scanStatus.textContent = '✗ ' + err.message;
      scanStatus.style.color = '#ff9580';
    }
  });
});
