// background.js — Service worker for WWWorkRemote Ingestion Assistant
//
// Message relay map:
//   OPEN_PANEL         content.js → background → storage + sidePanel.open()
//   UPDATE_PANEL_DATA  content.js → background → storage only (panel already open)
//   SUBMIT_JOB         sidepanel.js → background → content.js (PANEL_SUBMIT)
//   REEXTRACT          sidepanel.js → background → content.js
//   UPDATE_DESCRIPTION content.js → background → storage (desc-only patch)
//   API_FETCH          content.js → background → fetch (bypasses page CSP)

const SESSION_KEY = 'wwr_panel_state';

function buildPanelState(msg, tabId) {
  return {
    tabId,
    mode:      msg.mode,
    wwrId:     msg.wwrId,
    leadId:    msg.leadId,
    extracted: msg.extracted,
    provider:  msg.provider,
    pageUrl:   msg.pageUrl,
    pageTitle: msg.pageTitle,
    stale:     false,
  };
}

chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {

  // ── OPEN_PANEL ─────────────────────────────────────────────────────────────
  // Must be called synchronously within the tab's user gesture window --
  // chrome.sidePanel.open() rejects once any awaited work pushes past it.
  // content.js calls this FIRST (before running extraction), then follows up
  // with UPDATE_PANEL_DATA once real data is ready.
  if (msg.type === 'OPEN_PANEL') {
    const tabId = sender.tab?.id;
    if (!tabId) { sendResponse({ ok: false, error: 'No tab ID in sender' }); return; }

    const state = buildPanelState(msg, tabId);
    chrome.storage.session.set({ [SESSION_KEY]: state }, () => {
      chrome.sidePanel.open({ tabId })
        .then(() => sendResponse({ ok: true }))
        .catch(err => sendResponse({ ok: false, error: err.message }));
    });
    return true;
  }

  // ── UPDATE_PANEL_DATA ────────────────────────────────────────────────────
  // Patches the already-open panel's storage state without calling
  // sidePanel.open() again -- avoids a second, likely-gesture-expired call.
  if (msg.type === 'UPDATE_PANEL_DATA') {
    const tabId = sender.tab?.id;
    if (!tabId) { sendResponse({ ok: false, error: 'No tab ID in sender' }); return; }

    chrome.storage.session.set({ [SESSION_KEY]: buildPanelState(msg, tabId) }, () => {
      sendResponse({ ok: true });
    });
    return true;
  }

  // ── API_FETCH ────────────────────────────────────────────────────────────
  // content.js proxies its Rails API calls through here instead of fetching
  // directly from the page's context -- some sites' CSP blocks content-script
  // fetches (seen on LinkedIn: "TypeError: Failed to fetch"); a background
  // service worker isn't subject to any page's CSP at all.
  if (msg.type === 'API_FETCH') {
    fetch(msg.url, { method: msg.method || 'GET', headers: msg.headers || {}, body: msg.body })
      .then(async response => {
        let data = {};
        try { data = await response.json(); } catch (_) { /* non-JSON body */ }
        sendResponse({ ok: response.ok, status: response.status, data });
      })
      .catch(err => sendResponse({ ok: false, error: err.message }));
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
