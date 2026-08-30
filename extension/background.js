// background.js — Service worker for WWWorkRemote Ingestion Assistant
//
// Message relay map:
//   OPEN_PANEL         content.js → background → storage + sidePanel.open()
//   UPDATE_PANEL_DATA  content.js → background → storage only (panel already open)
//   APPLICATION_FIELDS_UPDATED content.js → background → storage field patch
//   SUBMIT_JOB         sidepanel.js → background → content.js (PANEL_SUBMIT)
//   REEXTRACT          sidepanel.js → background → content.js
//   GENERATE_ANSWER    sidepanel.js → background → content.js (TASK-78)
//   SET_APPLICATION_STATUS sidepanel.js → background → content.js (TASK-78)
//   UPDATE_DESCRIPTION content.js → background → storage (desc-only patch)
//   API_FETCH          content.js → background → fetch (bypasses page CSP)
//   PICKER_START       sidepanel.js → background → content.js (element picker)
//   PICKER_RESULT      content.js → background → storage (picker patch)
//   FILL_APPLICATION_FIELD sidepanel.js → background → content.js
//   DIAG_LOG           content.js/sidepanel.js → background → storage (capped log)
//   PROVIDER_DETECTED  content.js → background → chrome.action badge (per tab)

const SESSION_KEY = 'wwr_panel_state';
const TAB_STATES_KEY = 'wwr_panel_states';
const IS_LOCAL_BUILD = !('update_url' in chrome.runtime.getManifest());

// Read-only CDP probe for the local sandbox. It answers whether accessibility
// and DOM snapshots can provide stable recorder evidence before any driver
// behavior is introduced.
async function captureCdpSnapshot(tabId) {
  if (!IS_LOCAL_BUILD) throw new Error('CDP capture is available only in the local extension build');

  await chrome.debugger.attach({ tabId }, '1.3');
  try {
    await chrome.debugger.sendCommand({ tabId }, 'Accessibility.enable');
    const accessibility = await chrome.debugger.sendCommand({ tabId }, 'Accessibility.getFullAXTree');
    const domSnapshot = await chrome.debugger.sendCommand({ tabId }, 'DOMSnapshot.captureSnapshot', {
      computedStyles: ['display', 'visibility'], includePaintOrder: false, includeTextColorOpacities: false,
    });
    return summarizeCdpSnapshot(accessibility, domSnapshot);
  } finally {
    await chrome.debugger.detach({ tabId }).catch(() => {});
  }
}

function summarizeCdpSnapshot(accessibility, domSnapshot) {
  const formRoles = new Set(['textbox', 'combobox', 'checkbox', 'radio', 'listbox', 'spinbutton']);
  const fields = (accessibility.nodes || [])
    .filter(node => formRoles.has(node.role?.value))
    .slice(0, 100)
    .map(node => ({
      role: node.role?.value || null,
      name: node.name?.value || null,
      required: node.properties?.some(property => property.name === 'required' && property.value?.value === true) || false,
    }));
  return {
    capturedAt: new Date().toISOString(),
    accessibilityNodeCount: accessibility.nodes?.length || 0,
    formFieldCount: fields.length,
    fields,
    domSnapshotNodeCount: domSnapshot.nodes?.nodeName?.length || 0,
    domSnapshotStringCount: domSnapshot.strings?.length || 0,
  };
}

// Chrome will not permit an unsolicited page-load open, but it does support
// opening from an explicit toolbar/keyboard action. Keep the panel one action
// away and let the content script update its state as pages settle.
chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true }).catch(() => {});

chrome.commands.onCommand.addListener(async (command) => {
  if (!['open-wwworkremote-panel', 'open-wwworkremote-panel-alt'].includes(command)) return;
  const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
  if (!tab?.id) return;
  try {
    if (typeof chrome.sidePanel.close === 'function') await chrome.sidePanel.close({ tabId: tab.id });
  } catch (_) { /* close is optional across Chrome versions */ }
  try { await chrome.sidePanel.open({ tabId: tab.id }); }
  catch (error) {
    chrome.runtime.sendMessage({ type: 'EXTENSION_ERROR', event_name: 'shortcut_open', phase: 'command',
      error_name: error?.name || 'SidePanelOpenError', error_message: String(error?.message || error).slice(0, 500),
      recoverable: true, build_version: chrome.runtime.getManifest().version,
      context: { command, tab_id: tab.id } }).catch(() => {});
  }
});

// ── Toolbar badge ────────────────────────────────────────────────────────
// Clear on every navigation start; only a PROVIDER_DETECTED message (sent
// once content.js runs on the new page) re-lights it. Cheaper than tracking
// per-tab state here, and it means a failed/skipped message just leaves the
// badge off rather than stuck showing a stale board.
chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (changeInfo.status === 'loading') chrome.action.setBadgeText({ tabId, text: '' });
});

function buildPanelState(msg, tabId, priorState = null) {
  return {
    tabId,
    mode:      msg.mode,
    // Workday drops the query string when it redirects to userHome. Keep the
    // tracked posting only for an explicit completion event from that tab.
    wwrId:     msg.wwrId || (msg.applicationCompletion ? priorState?.wwrId : null),
    leadId:    msg.leadId,
    extracted: msg.extracted,
    applicationQA: msg.applicationQA || { matches: [], unmatched: [] },
    profileFields: msg.profileFields || null,
    applicationStatus: msg.applicationStatus || null,
    applicationContext: msg.applicationContext || null,
    applicationFields: msg.applicationFields || [],
    applicationCompletion: msg.applicationCompletion || null,
    provider:  msg.provider,
    pageUrl:   msg.pageUrl,
    pageTitle: msg.pageTitle,
    // Correlation spine (ADR 010): the guided session token, if this tab is
    // a guided lap. Sticky across UPDATE_PANEL_DATA once set.
    guidedSessionToken: msg.guidedSessionToken || priorState?.guidedSessionToken || null,
    stale:     false,
  };
}

chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {

  if (msg.type === 'CDP_CAPTURE_SNAPSHOT') {
    captureCdpSnapshot(msg.tabId)
      .then(snapshot => sendResponse({ ok: true, snapshot }))
      .catch(error => sendResponse({ ok: false, error: error.message }));
    return true;
  }

  // ── OPEN_PANEL ─────────────────────────────────────────────────────────────
  // Must be called synchronously within the tab's user gesture window --
  // chrome.sidePanel.open() rejects once any awaited work pushes past it.
  // content.js calls this FIRST (before running extraction), then follows up
  // with UPDATE_PANEL_DATA once real data is ready.
  if (msg.type === 'OPEN_PANEL') {
    const tabId = sender.tab?.id;
    if (!tabId) { sendResponse({ ok: false, error: 'No tab ID in sender' }); return; }

    chrome.storage.session.get([SESSION_KEY, TAB_STATES_KEY], (data) => {
      const tabStates = data[TAB_STATES_KEY] || {};
      const state = buildPanelState(msg, tabId, tabStates[tabId]);
      chrome.storage.session.set({ [SESSION_KEY]: state, [TAB_STATES_KEY]: { ...tabStates, [tabId]: state } }, () => {
        chrome.sidePanel.open({ tabId })
        .then(() => sendResponse({ ok: true }))
        .catch(err => sendResponse({ ok: false, recoverable: true, error: err.message }));
      });
    });
    return true;
  }

  // ── UPDATE_PANEL_DATA ────────────────────────────────────────────────────
  // Patches the already-open panel's storage state without calling
  // sidePanel.open() again -- avoids a second, likely-gesture-expired call.
  if (msg.type === 'UPDATE_PANEL_DATA') {
    const tabId = sender.tab?.id;
    if (!tabId) { sendResponse({ ok: false, error: 'No tab ID in sender' }); return; }

    chrome.storage.session.get(TAB_STATES_KEY, (data) => {
      const tabStates = data[TAB_STATES_KEY] || {};
      const state = buildPanelState(msg, tabId, tabStates[tabId]);
      chrome.storage.session.set({ [SESSION_KEY]: state, [TAB_STATES_KEY]: { ...tabStates, [tabId]: state } }, () => {
      sendResponse({ ok: true });
      });
    });
    return true;
  }

  if (msg.type === 'APPLICATION_FIELDS_UPDATED') {
    const tabId = sender.tab?.id;
    if (!tabId) return;
    chrome.storage.session.get([SESSION_KEY, TAB_STATES_KEY], (data) => {
      const current = data[SESSION_KEY];
      const tabStates = data[TAB_STATES_KEY] || {};
      const prior = tabStates[tabId] || current;
      if (!prior) return;
      const patched = { ...prior, tabId, applicationFields: msg.applicationFields || [],
        pageUrl: msg.pageUrl || prior.pageUrl, pageTitle: msg.pageTitle || prior.pageTitle,
        guidedSessionToken: msg.guidedSessionToken || prior.guidedSessionToken || null, stale: false };
      chrome.storage.session.set({ [SESSION_KEY]: patched,
        [TAB_STATES_KEY]: { ...tabStates, [tabId]: patched } });
    });
    return;
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

  // ── FILL_APPLICATION_FIELD ────────────────────────────────────────────────
  // The panel owns the answer; the content script owns the live DOM element.
  if (msg.type === 'FILL_APPLICATION_FIELD') {
    chrome.storage.session.get(SESSION_KEY, (data) => {
      const state = data[SESSION_KEY];
      if (!state?.tabId) {
        sendResponse({ ok: false, error: 'No active application page' });
        return;
      }
      chrome.tabs.sendMessage(state.tabId, {
        type: 'FILL_APPLICATION_FIELD', fieldKey: msg.fieldKey, value: msg.value,
        source: msg.source || 'manual',
      }, (response) => {
        if (chrome.runtime.lastError) sendResponse({ ok: false, error: chrome.runtime.lastError.message });
        else sendResponse(response);
      });
    });
    return true;
  }

  if (msg.type === 'REFRESH_APPLICATION_FIELDS') {
    chrome.storage.session.get(SESSION_KEY, (data) => {
      const state = data[SESSION_KEY];
      if (!state?.tabId) { sendResponse({ ok: false, error: 'No active application page' }); return; }
      chrome.tabs.sendMessage(state.tabId, { type: 'REFRESH_APPLICATION_FIELDS' }, response => {
        if (chrome.runtime.lastError) sendResponse({ ok: false, error: chrome.runtime.lastError.message });
        else sendResponse(response || { ok: true });
      });
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
        { type: 'PICKER_START', fieldName: msg.fieldName, mapping: !!msg.mapping },
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

  if (msg.type === 'EXTENSION_ERROR') {
    chrome.storage.session.get(SESSION_KEY, (data) => {
      const state = data[SESSION_KEY];
      if (state) {
        const entry = { level: 'error', text: `${msg.event_name}: ${msg.error_message}`, ts: Date.now(), detail: msg };
        chrome.storage.session.set({ [SESSION_KEY]: { ...state, diagnostics: [...(state.diagnostics || []), entry].slice(-200) } });
      }
      // Correlation spine (ADR 010): stamp the guided session token from the
      // panel state when the error happened during a guided lap.
      const token = msg.guided_session_token || state?.guidedSessionToken || null;
      fetch('http://localhost:31000/api/v0/extension_error_events', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ extension_error_event: msg, guided_session_token: token }),
      }).catch(() => {});
    });
  }
});
