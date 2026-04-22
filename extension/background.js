// background.js — Service worker for WWWorkRemote Ingestion Assistant
//
// Message relay map:
//   OPEN_PANEL         content.js → background → storage + sidePanel.open()
//   SUBMIT_JOB         sidepanel.js → background → content.js (PANEL_SUBMIT)
//   REEXTRACT          sidepanel.js → background → content.js
//   UPDATE_DESCRIPTION content.js → background → storage (desc-only patch)

const SESSION_KEY = 'wwr_panel_state';

chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {

  // ── OPEN_PANEL ─────────────────────────────────────────────────────────────
  if (msg.type === 'OPEN_PANEL') {
    const tabId = sender.tab?.id;
    if (!tabId) { sendResponse({ ok: false, error: 'No tab ID in sender' }); return; }

    const state = {
      tabId,
      wwrId:     msg.wwrId,
      extracted: msg.extracted,
      provider:  msg.provider,
      pageUrl:   msg.pageUrl,
      pageTitle: msg.pageTitle,
      stale:     false,
    };

    chrome.storage.session.set({ [SESSION_KEY]: state }, () => {
      chrome.sidePanel.open({ tabId })
        .then(() => sendResponse({ ok: true }))
        .catch(err => sendResponse({ ok: false, error: err.message }));
    });
    return true;
  }

  // ── SUBMIT_JOB ─────────────────────────────────────────────────────────────
  if (msg.type === 'SUBMIT_JOB') {
    chrome.storage.session.get(SESSION_KEY, (data) => {
      const state = data[SESSION_KEY];
      if (!state?.tabId) {
        sendResponse({ ok: false, error: 'No active job session — reload the job page' });
        return;
      }
      chrome.tabs.sendMessage(
        state.tabId,
        { type: 'PANEL_SUBMIT', editedData: msg.editedData, wwrId: msg.wwrId },
        (response) => {
          if (chrome.runtime.lastError) sendResponse({ ok: false, error: chrome.runtime.lastError.message });
          else sendResponse(response);
        }
      );
    });
    return true;
  }

  // ── REEXTRACT ──────────────────────────────────────────────────────────────
  // Sent by sidepanel.js; relayed to the content script on the originating tab.
  if (msg.type === 'REEXTRACT') {
    chrome.storage.session.get(SESSION_KEY, (data) => {
      const state = data[SESSION_KEY];
      if (!state?.tabId) {
        sendResponse({ ok: false, error: 'No active job session' });
        return;
      }
      chrome.tabs.sendMessage(
        state.tabId,
        { type: 'REEXTRACT', descOnly: !!msg.descOnly },
        (response) => {
          if (chrome.runtime.lastError) sendResponse({ ok: false, error: chrome.runtime.lastError.message });
          else sendResponse(response);
        }
      );
    });
    return true;
  }

  // ── UPDATE_DESCRIPTION ────────────────────────────────────────────────────
  // Sent by content.js after a desc-only re-read; patches only description
  // fields in storage so the panel can update without clobbering user edits.
  if (msg.type === 'UPDATE_DESCRIPTION') {
    chrome.storage.session.get(SESSION_KEY, (data) => {
      const state = data[SESSION_KEY];
      if (!state) return;
      const patched = {
        ...state,
        stale: false,
        extracted: {
          ...state.extracted,
          description_text: msg.description_text,
          description_html: msg.description_html,
        },
      };
      chrome.storage.session.set({ [SESSION_KEY]: patched });
    });
  }
});
