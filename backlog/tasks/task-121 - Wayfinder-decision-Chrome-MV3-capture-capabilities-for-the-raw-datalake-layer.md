---
id: TASK-121
title: 'Wayfinder decision: Chrome MV3 capture capabilities for the raw datalake layer'
status: Done
assignee:
  - '@claude'
created_date: '2026-08-29 17:23'
updated_date: '2026-08-29 17:32'
labels:
  - 'wayfinder:research'
  - application-capture-datalake
  - 'wayfinder-map:doc-7'
dependencies: []
references:
  - >-
    backlog/docs/wayfinder/doc-7 -
    Wayfinder-map-link-to-application-capture-and-the-datalake.md
  - docs/architecture/panoramic-view.md
  - docs/architecture/signature-registry.md
  - extension/manifest.json
ordinal: 137000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Decision ticket for wayfinder map doc-7 "Wayfinder map: link-to-application capture and the datalake" (backlog/docs/wayfinder/doc-7). Research type (AFK) — resolved by a subagent via the research skill, findings written to docs/research/.

## Question

What can the wwworkremote Chrome extension actually capture for the datalake raw layer, and at what permission cost?

The map's decided raw-asset scope is greedy: a DOM snapshot per meaningful transition, full HAR including response bodies, and a screenshot per transition. Before the raw-capture seam can be designed, establish against primary sources (Chrome extension MV3 docs, chrome.* API references, the DevTools Protocol docs):

- Full-page DOM serialization from a content script — what is reliably capturable (shadow DOM, iframes, computed styles, resource inlining) and what is not.
- Response bodies — `chrome.webRequest` cannot read bodies in MV3; what actually can (`chrome.debugger` / DevTools Protocol `Network.getResponseBody`, `declarativeNetRequest` limitations), and the UX cost (the debugger banner, one-debuggee-per-tab).
- Screenshots — `chrome.tabs.captureVisibleTab` vs DevTools Protocol full-page capture; permissions and rate limits.
- The manifest permissions each path requires (`<all_urls>`, `debugger`, `scripting`, host permissions) and which of those meaningfully widen the extension's trust footprint on Mike's machine.
- Whether an unpacked/dev extension (IS_LOCAL_BUILD) can hold permissions a store build should not.

Findings feed the "Guided-recorder raw-capture seam" ticket, which is blocked on this one.
<!-- SECTION:DESCRIPTION:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: research-subagent
created: 2026-08-29 17:31
---
Research complete (branch `research/mv3-capture-capabilities`, commit 5e8fd6f3). Findings: `docs/research/mv3-capture-capabilities.md`. Primary sources only.

Key results:
- **DOM**: content-script `Element.getHTML({serializableShadowRoots:true, shadowRoots:[...]})` (Baseline 2024) serializes light DOM + open shadow roots + same-origin frames. Closed shadow roots need a `document_start` MAIN-world `attachShadow` shim (out of scope v1). Cross-origin iframes are opaque. No API inlines CSS/images/computed-styles — use CDP `DOMSnapshot.captureSnapshot` for styles. `getInnerHTML`/`DOMParser includeShadowRoots` removed in Chrome 129.
- **Response bodies**: `chrome.webRequest` cannot read them (any MV version); `declarativeNetRequest` cannot by design. Only path = `chrome.debugger` + CDP `Network.getResponseBody`/`getRequestPostData` (prefer `streamResourceContent` to beat buffer eviction). Extension already holds `debugger`.
- **Screenshots**: `tabs.captureVisibleTab` = viewport only, `activeTab` ok, 2/sec cap. Full-page = CDP `Page.captureScreenshot` with `captureBeyondViewport:true` — free if already attached.
- **Cost**: `chrome.debugger` shows a per-tab “started debugging this browser” banner and its session is killed when DevTools opens on the tab (`onDetach: canceled_by_user`). Warning strings: “Access the page debugger backend” + “Read and change all your data on all websites”. Suppressible only via `--silent-debugger-extension-api` or enterprise install — dev-machine only.
- **Unpacked vs store**: extension already carries `activeTab` + `debugger` + broad host list, so the raw layer adds near-zero incremental trust. A hypothetical CWS build should drop `debugger` (CWS narrowest-permissions policy + review friction); wwworkremote is unpacked-by-design so it's fine. `onRuleMatchedDebug` is unpacked-only by Chrome rule.

TASK-122 recommendation (in doc §7): greedy raw scope (DOM per transition + full HAR w/ bodies + screenshot per transition) IS achievable today with current permissions. Build debugger-sourced captures as individually optional, record capture gaps (cross-origin frames, closed roots, post-detach transitions) explicitly in manifest.json. Drop: closed-shadow-DOM capture, content-script resource inliner, adding `<all_urls>` or `webRequest`.

Not closing this ticket — human resolves.
---

author: wayfinder
created: 2026-08-29 17:32
---
RESOLVED (research subagent, branch `research/mv3-capture-capabilities` commit 5e8fd6f3, not pushed). Findings: `docs/research/mv3-capture-capabilities.md`.

Bottom line: the map's greedy raw-asset scope (DOM per transition + full HAR WITH response bodies + screenshot per transition) is achievable today with permissions the extension already holds (`activeTab`, `debugger`, named host list) -- **no new scary permission needed**.
- DOM: content-script `Element.getHTML({serializableShadowRoots:true, shadowRoots:[...]})` (Baseline 2024) -- light DOM + open shadow roots + same-origin frames. Closed shadow roots + cross-origin frames are gaps to record, not close.
- Response bodies: ONLY `chrome.debugger` + CDP `Network.getResponseBody` / `streamResourceContent` (webRequest & DNR structurally cannot). UX tax: the per-tab 'started debugging this browser' banner, and the extension's debugger session dies when DevTools opens on the tab (`onDetach` `canceled_by_user`).
- Full-page screenshots: CDP `Page.captureScreenshot` + `captureBeyondViewport` in the same debugger session; `tabs.captureVisibleTab` (viewport only, 2/sec) as no-debugger fallback.
- Seam must make debugger-sourced captures individually optional and record capture gaps explicitly in manifest.json.
- Drop/defer for v1: closed-shadow-DOM capture (needs a document_start MAIN-world attachShadow shim -- separate task), content-script resource inliner, adding <all_urls> or webRequest.

Unblocks TASK-122 (guided-recorder raw-capture seam).
---
<!-- COMMENTS:END -->
