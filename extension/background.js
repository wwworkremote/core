// background.js — Service worker for WWWorkRemote Ingestion Assistant
//
// Message relay map:
//   OPEN_PANEL         content.js → background → storage + sidePanel.open()
//   UPDATE_PANEL_DATA  content.js → background → storage only (panel already open)
//   SUBMIT_JOB         sidepanel.js → background → content.js (PANEL_SUBMIT)
//   REEXTRACT          sidepanel.js → background → content.js
//   GENERATE_ANSWER    sidepanel.js → background → content.js (TASK-78)
//   SET_APPLICATION_STATUS sidepanel.js → background → content.js (TASK-78)
//   UPDATE_DESCRIPTION content.js → background → storage (desc-only patch)
//   API_FETCH          content.js → background → fetch (bypasses page CSP)
//   PICKER_START       sidepanel.js → background → content.js (element picker)
//   PICKER_RESULT      content.js → background → storage (picker patch)
//   DIAG_LOG           content.js/sidepanel.js → background → storage (capped log)
//   PROVIDER_DETECTED  content.js → background → chrome.action badge (per tab)

const SESSION_KEY = 'wwr_panel_state';

// ── Toolbar badge ────────────────────────────────────────────────────────
// Clear on every navigation start; only a PROVIDER_DETECTED message (sent
// once content.js runs on the new page) re-lights it. Cheaper than tracking
// per-tab state here, and it means a failed/skipped message just leaves the
// badge off rather than stuck showing a stale board.
chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (changeInfo.status === 'loading') chrome.action.setBadgeText({ tabId, text: '' });
});

function buildPanelState(msg, tabId) {
  return {
    tabId,
    mode:      msg.mode,
    wwrId:     msg.wwrId,
    leadId:    msg.leadId,
    extracted: msg.extracted,
    applicationQA: msg.applicationQA || { matches: [], unmatched: [] },
    profileFields: msg.profileFields || null,
    applicationStatus: msg.applicationStatus || null,
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

  // ── GENERATE_ANSWER (TASK-78) ───────────────────────────────────────────────
  // Sent by sidepanel.js for an unmatched application question; relayed to the
  // content script on the originating tab, which POSTs it to the Rails API.
  if (msg.type === 'GENERATE_ANSWER') {
    chrome.storage.session.get(SESSION_KEY, (data) => {
      const state = data[SESSION_KEY];
      if (!state?.tabId) {
        sendResponse({ ok: false, error: 'No active job session' });
        return;
      }
      chrome.tabs.sendMessage(
        state.tabId,
        { type: 'GENERATE_ANSWER', questionText: msg.questionText },
        (response) => {
          if (chrome.runtime.lastError) sendResponse({ ok: false, error: chrome.runtime.lastError.message });
          else sendResponse(response);
        }
      );
    });
    return true;
  }

  // ── SET_APPLICATION_STATUS (TASK-78) ───────────────────────────────────────
  // Sent by sidepanel.js when the user advances the lifecycle from the panel;
  // same relay shape as GENERATE_ANSWER.
  if (msg.type === 'SET_APPLICATION_STATUS') {
    chrome.storage.session.get(SESSION_KEY, (data) => {
      const state = data[SESSION_KEY];
      if (!state?.tabId) {
        sendResponse({ ok: false, error: 'No active job session' });
        return;
      }
      chrome.tabs.sendMessage(
        state.tabId,
        { type: 'SET_APPLICATION_STATUS', event: msg.event },
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

  // ── PICKER_START ───────────────────────────────────────────────────────────
  // Sent by sidepanel.js when the user clicks "Teach" next to a field;
  // relayed to the content script on the originating tab, which enters
  // element-picker mode and responds immediately (not waiting on the click).
  if (msg.type === 'PICKER_START') {
    chrome.storage.session.get(SESSION_KEY, (data) => {
      const state = data[SESSION_KEY];
      if (!state?.tabId) {
        sendResponse({ ok: false, error: 'No active job session' });
        return;
      }
      chrome.tabs.sendMessage(
        state.tabId,
        { type: 'PICKER_START', fieldName: msg.fieldName },
        (response) => {
          if (chrome.runtime.lastError) sendResponse({ ok: false, error: chrome.runtime.lastError.message });
          else sendResponse(response);
        }
      );
    });
    return true;
  }

  // ── PICKER_RESULT ──────────────────────────────────────────────────────────
  // Sent by content.js once the user clicks an element (or cancels via
  // Escape) -- patches storage so the panel's onChanged listener can pick
  // it up and call the API, independent of PICKER_START's response, since
  // the click can come an arbitrary amount of time after picker mode starts.
  if (msg.type === 'PICKER_RESULT') {
    chrome.storage.session.get(SESSION_KEY, (data) => {
      const state = data[SESSION_KEY];
      if (!state) return;
      chrome.storage.session.set({ [SESSION_KEY]: { ...state, pickerResult: msg.result } });
    });
  }

  // ── PROVIDER_DETECTED ────────────────────────────────────────────────────
  // Sent by content.js once per page load, right after it determines
  // whether the current host matches a supported provider -- lets the
  // toolbar badge show capture is available without opening the popup.
  if (msg.type === 'PROVIDER_DETECTED') {
    const tabId = sender.tab?.id;
    if (tabId) {
      if (msg.provider) {
        chrome.action.setBadgeText({ tabId, text: '✓' });
        chrome.action.setBadgeBackgroundColor({ tabId, color: '#8aff80' });
      } else {
        chrome.action.setBadgeText({ tabId, text: '' });
      }
    }
  }

  // ── DIAG_LOG ─────────────────────────────────────────────────────────────
  // Fire-and-forget from content.js's LOG* helpers and sidepanel.js's
  // setStatus -- appends to a capped, storage-backed diagnostics feed so
  // the panel can show what's happening without DevTools open. Dropped
  // silently if no panel session exists yet (nothing would show it).
  if (msg.type === 'DIAG_LOG') {
    chrome.storage.session.get(SESSION_KEY, (data) => {
      const state = data[SESSION_KEY];
      if (!state) return;
      const entry = { level: msg.level, text: msg.text, ts: msg.ts, detail: msg.detail };
      const diagnostics = [...(state.diagnostics || []), entry].slice(-200);
      chrome.storage.session.set({ [SESSION_KEY]: { ...state, diagnostics } });
    });
  }
});
