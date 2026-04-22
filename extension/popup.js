// WWWorkRemote Popup
// Manages the configurable API URL stored in chrome.storage.local.
// The content script reads this value before every sync — change it here
// if Rails is running on a non-default port or host.

const DEFAULT_API = 'http://localhost:3010';

document.addEventListener('DOMContentLoaded', () => {
  const input      = document.getElementById('api-url');
  const saveBtn    = document.getElementById('save-btn');
  const saveStatus = document.getElementById('save-status');

  // Load saved URL (or show default as placeholder)
  chrome.storage.local.get('apiUrl', ({ apiUrl }) => {
    input.value = apiUrl || DEFAULT_API;
  });

  saveBtn.addEventListener('click', () => {
    const raw = input.value.trim();
    // Normalise: strip trailing slash, ensure http(s):// prefix
    const url = raw.replace(/\/$/, '') || DEFAULT_API;

    if (!/^https?:\/\/.+/.test(url)) {
      saveStatus.textContent = '⚠ Must start with http:// or https://';
      saveStatus.style.color = '#ff5555';
      return;
    }

    chrome.storage.local.set({ apiUrl: url }, () => {
      input.value            = url;
      saveStatus.textContent = '✓ Saved';
      saveStatus.style.color = '#50fa7b';
      setTimeout(() => { saveStatus.textContent = ''; }, 2500);
    });
  });

  // Save on Enter key
  input.addEventListener('keydown', e => {
    if (e.key === 'Enter') saveBtn.click();
  });
});
