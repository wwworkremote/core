# Chrome MV3 capture capabilities for the datalake raw layer

**Doc location.** Sits with its neighbours in `docs/research/` (`chrome-built-in-ai-flags.md`,
`chrome-platform-and-wasm-leverage.md`) — external-technology reconnaissance feeding a
backlog decision, not a description of this system. This one resolves **TASK-121** (wayfinder
map doc-7) and feeds **TASK-122** (guided-recorder raw-capture seam).

**Question.** Given the wwworkremote extension (MV3, currently loaded unpacked, `permissions:
["activeTab","scripting","storage","sidePanel","debugger"]`, ~24 named `host_permissions`),
what can it actually capture for a machine-local raw datalake layer — full-page DOM
snapshots, HTTP response bodies, screenshots — and what does each cost in manifest
permissions and user-visible trust?

**Sources.** Primary only: `developer.chrome.com` extension docs, the `chrome.*` API
reference, the Chrome DevTools Protocol reference (`chromedevtools.github.io`), MDN for
web-platform DOM APIs, and Chromium source / issue tracker. Every claim below links to the
doc that owns it.

---

## 1. Bottom line

- **DOM snapshot**: a content script can serialize the top document and every **same-origin**
  frame to a self-contained HTML string, including **open** shadow roots, using
  `Element.getHTML({ serializableShadowRoots: true, shadowRoots: [...] })` (Baseline 2024).
  **Closed** shadow roots need an explicit `ShadowRoot` reference — obtainable only if the
  extension patches `attachShadow` in the page's MAIN world before the page runs, which the
  current `document_end` content script does not do. **Cross-origin iframes** are opaque to a
  content script — you get one snapshot per frame the extension is injected into and must
  stitch them, and you cannot reach a frame on a host not in `host_permissions`. Computed
  styles and external CSS/images are **not** inlined by any serialization API — that is
  bespoke walk-the-tree work, and CDP `DOMSnapshot.captureSnapshot` does it far more cheaply.
- **Response bodies**: `chrome.webRequest` **cannot** read them — never could, any manifest
  version. `declarativeNetRequest` cannot either (by design). The **only** in-extension way
  is `chrome.debugger` + CDP `Network.getResponseBody` / `Network.getRequestPostData`. The
  extension already holds the `debugger` permission. Cost: a **per-tab** "started debugging
  this browser" banner, and **opening DevTools on that tab terminates the extension's
  debugger session** (`onDetach` reason `canceled_by_user`).
- **Screenshots**: `chrome.tabs.captureVisibleTab` gives **visible viewport only**, needs
  `activeTab` or `<all_urls>`, throttled to **2 calls/sec**. Full-page / element-clipped
  capture needs `chrome.debugger` + CDP `Page.captureScreenshot` with `clip` +
  `captureBeyondViewport: true` — same debugger cost as response bodies, so if you are
  already attached for HAR bodies, full-page screenshots are nearly free.
- **Trust footprint**: `debugger` is the one that matters. Its install warning is **"Access
  the page debugger backend"** *and* **"Read and change all your data on all websites"**, and
  per the Chromium security FAQ it "may … sidestep other typical restrictions, such as host
  permissions or file access." The broad `host_permissions` list already earns "Read and
  change your data on [n] sites"; `scripting` / `activeTab` add nothing scary on top.
- **Unpacked vs store**: no hard Chrome rule bans `debugger` from a Web Store build, but CWS
  "narrowest permissions" policy + the scary warning + heavy review make it a poor fit to
  ship. Unpacked/dev-mode is the honest home for it, and one capability
  (`declarativeNetRequestFeedback` / `onRuleMatchedDebug`) is **unpacked-only** by Chrome.

---

## 2. Full-page DOM serialization from a content script

### 2.1 What a content script can touch

A content script runs in an **isolated world** but **shares the page DOM**: "Content scripts
… are able to make changes to their DOM environment" and "live in an isolated world, allowing
a content script to make changes to its JavaScript environment without conflicting with the
page" — https://developer.chrome.com/docs/extensions/develop/concepts/content-scripts

Frames: a content script is injected per-frame, and only into frames whose URL matches
`matches` (and only if `"all_frames": true`; default is top frame only) —
https://developer.chrome.com/docs/extensions/develop/concepts/content-scripts#frames
Cross-origin iframe DOM is **not reachable** from the parent frame's content script — the
same-origin policy applies to `iframe.contentDocument` exactly as it does for page script
(HTML spec, "Cross-origin objects":
https://html.spec.whatwg.org/multipage/browsers.html#cross-origin-objects). Practical
consequence for a snapshot: you serialize each frame the extension is injected into
separately and reassemble by frame id; a frame on a host not in `host_permissions` (ad
iframes, embedded third-party widgets, some ATS payment/verification steps) yields nothing.

The current manifest sets neither `all_frames` nor `match_about_blank` on the `content.js`
entry, so today only the **top document** of a matching page is instrumented.

### 2.2 Serialization APIs and their status

| API | Status | What it does |
|---|---|---|
| `Element.innerHTML` / `outerHTML` | Stable, universal | Serializes light DOM only. **Skips all shadow roots.** |
| `Element.getHTML(options)` | **Baseline 2024** (shipped Chrome **125**) | Serializes an element; with `{serializableShadowRoots: true}` includes shadow roots marked `serializable`; with `{shadowRoots: [root, …]}` includes those specific roots "regardless of whether they are marked as `serializable`, or if they are open or closed." — https://developer.mozilla.org/en-US/docs/Web/API/Element/getHTML |
| `Element.getInnerHTML({includeShadowRoots:true})` | **Removed, Chrome 129** | Non-standard prototype API. "the old `getInnerHTML()` method is now being removed from Chrome, and you should use `getHTML()` as a replacement" — https://developer.chrome.com/release-notes/129 . Do not use. |
| `DOMParser` + `{includeShadowRoots:true}` | **Removed** | Replaced by `Document.parseHTMLUnsafe()` / `Element.setHTMLUnsafe()` for the round-trip (parse side) — https://developer.chrome.com/release-notes/129 |
| CDP `DOMSnapshot.captureSnapshot` | Stable CDP (needs `chrome.debugger`) | "the full DOM tree of the root node (including iframes, template contents, and imported documents) in a flattened array, as well as layout and white-listed computed style information" — https://chromedevtools.github.io/devtools-protocol/tot/DOMSnapshot/#method-captureSnapshot |

### 2.3 Shadow DOM: open vs closed

- **Open** shadow roots: reachable from a content script via `element.shadowRoot`. You can
  walk the tree, collect the roots, and pass them to `getHTML({shadowRoots: [...]})`. Fully
  capturable.
- **`serializable` shadow roots**: `getHTML({serializableShadowRoots:true})` picks these up
  automatically, but only if the page created them with `attachShadow({serializable:true})`
  or `<template shadowrootmode shadowrootserializable>` —
  https://developer.mozilla.org/en-US/docs/Web/API/ShadowRoot/serializable . Most ATS UIs
  will not, so you cannot rely on this flag.
- **Closed** shadow roots (`attachShadow({mode:"closed"})`): `element.shadowRoot` returns
  `null`. `getHTML` can serialize a closed root **only if you already hold the `ShadowRoot`
  object** — https://developer.mozilla.org/en-US/docs/Web/API/Element/getHTML . The only way
  to obtain it is to run in the page's **MAIN world** and monkey-patch
  `Element.prototype.attachShadow` **before the page calls it**, stashing every returned
  root. That needs `chrome.scripting.registerContentScripts` / a manifest content script
  with `"world": "MAIN"` and `"run_at": "document_start"` — https://developer.chrome.com/docs/extensions/reference/api/scripting/#type-ExecutionWorld
  — which the current `document_end` ISOLATED-world `content.js` is not. Even CDP does not
  hand you closed-root contents through the normal DOM domain without similar tricks.
  **Recommendation: treat closed shadow DOM as out of scope for v1.** Workday and some
  Greenhouse embeds use web components; spot-check whether their roots are closed before
  committing effort.

### 2.4 Computed styles and resource inlining

No serialization API inlines anything. For a visually faithful self-contained snapshot you
would have to:

- **Computed styles**: either walk the tree calling `getComputedStyle` per element (slow,
  and explodes file size), or use CDP `DOMSnapshot.captureSnapshot` with a `computedStyles`
  whitelist, which returns styles for the whole flattened tree in one call
  (https://chromedevtools.github.io/devtools-protocol/tot/DOMSnapshot/#method-captureSnapshot).
- **External CSS**: `fetch()` each stylesheet href from the content script (subject to the
  page's CSP and your `host_permissions`), or read `document.styleSheets[i].cssRules` for
  same-origin sheets and serialize them into a `<style>` block. Cross-origin sheets throw on
  `.cssRules` access.
- **Images / fonts**: `fetch()` + `FileReader`/`canvas` to `data:` URIs. Large, slow, and
  CSP-limited. CDP `Page.getResourceContent` / `Network.getResponseBody` is the cleaner
  route once attached.

**Verdict for the raw layer**: capture **outer HTML + open/serializable shadow roots** as
the cheap structural artifact from the content script, and get **computed styles + resource
bodies from CDP** in the same debugger session that captures HAR. Do not build a
tree-walking inliner in the content script.

---

## 3. HTTP response bodies

### 3.1 `chrome.webRequest` cannot read bodies — confirmed

`chrome.webRequest` exposes request/response **headers and metadata only**. `onBeforeRequest`
can carry `requestBody` (form/raw upload data) when `"requestBody"` is in `extraInfoSpec`,
but **there is no response-body accessor at any stage** (`onHeadersReceived`,
`onResponseStarted`, `onCompleted` included) —
https://developer.chrome.com/docs/extensions/reference/api/webRequest . MV3 additionally
removes blocking for most extensions: "`webRequestBlocking` is not available for extensions
… except policy installed extensions" —
https://developer.chrome.com/docs/extensions/reference/api/webRequest#permission_webrequestblocking
So `webRequest` is useful here only as a lightweight event feed ("a request to URL X of type
Y finished with status Z") to drive *when* to pull a body via another mechanism.

### 3.2 `declarativeNetRequest` cannot either — by design

DNR "lets extensions modify network requests without intercepting them and viewing their
content" — the privacy pitch is precisely that it never sees payloads —
https://developer.chrome.com/docs/extensions/reference/api/declarativeNetRequest . It can
block, redirect, upgrade scheme, and modify headers, nothing more. `onRuleMatchedDebug`
returns matched-rule + request metadata (URL, method, type), not content, and requires the
`declarativeNetRequestFeedback` permission and is **available to unpacked extensions only** —
https://developer.chrome.com/docs/extensions/reference/api/declarativeNetRequest#event-onRuleMatchedDebug

### 3.3 The only working path: `chrome.debugger` + CDP Network

- `chrome.debugger.attach({tabId}, "1.3")`, then `sendCommand(target, "Network.enable")` —
  "Enables network tracking, network events will now be delivered to the client" —
  https://chromedevtools.github.io/devtools-protocol/tot/Network/#method-enable
- On `Network.loadingFinished` (or `responseReceived`), call
  `Network.getResponseBody({requestId})` → `{ body, base64Encoded }` — "Returns content
  served for the given request" —
  https://chromedevtools.github.io/devtools-protocol/tot/Network/#method-getResponseBody
- POST bodies: `Network.getRequestPostData({requestId})` → `{ postData }` — "Returns post
  data sent with the request. Returns an error when no data was sent with the request" —
  https://chromedevtools.github.io/devtools-protocol/tot/Network/#method-getRequestPostData

**Known failure modes (primary-source):**

- `getResponseBody` fails with *"No data found for resource with given identifier"* when the
  body was evicted from the DevTools network buffer, never buffered (some redirects, 204s,
  streamed/cancelled responses), or served from certain caches. Mitigations: raise
  `Network.enable`'s `maxResourceBufferSize` / `maxTotalBufferSize` (experimental params,
  same URL as above), or use `Network.streamResourceContent({requestId})` — "Enables
  streaming of the response … the `dataReceived` event contains the data that was received
  during streaming" —
  https://chromedevtools.github.io/devtools-protocol/tot/Network/#method-streamResourceContent
  — started immediately on `responseReceived` so nothing is lost to eviction.
- Bodies must be pulled **while attached**; detach drops the buffer.

### 3.4 The UX / operational cost of `chrome.debugger`

- **The banner.** Whenever an extension attaches via `chrome.debugger`, Chrome shows a
  persistent infobar: *"&lt;Extension name&gt; started debugging this browser"* with a
  **Cancel** button; clicking Cancel detaches the extension. The banner is a deliberate
  Chrome security signal — the Chromium security FAQ ties it to the fact that the debugger
  API "may in some cases also sidestep other typical restrictions, such as host permissions
  or file access" —
  https://chromium.googlesource.com/chromium/src/+/main/extensions/docs/security_faq.md
  It can be suppressed only by launching Chrome with `--silent-debugger-extension-api`
  (documented switch, https://peter.sh/experiments/chromium-command-line-switches/#silent-debugger-extension-api)
  or by installing the extension via enterprise policy (the switch is in Chromium's switch
  list, `chrome/common/chrome_switches.cc` → `kSilentDebuggerExtensionAPI`; mirror:
  https://peter.sh/experiments/chromium-command-line-switches/#silent-debugger-extension-api).
  Both are acceptable for Mike's own dev machine; neither is available to a normal end user
  of a store build.
- **DevTools coexistence.** Per the official `onDetach` documentation, the extension's
  debugger session is terminated "when … Chrome DevTools is being invoked for the attached
  tab" —
  https://developer.chrome.com/docs/extensions/reference/api/debugger/#event-onDetach
  Detach reason is `canceled_by_user` —
  https://developer.chrome.com/docs/extensions/reference/api/debugger/#type-DetachReason
  So: **if Mike opens DevTools on the tab a guided session is recording, capture stops.**
  The recorder must detect `onDetach` and either re-attach (re-showing the banner) or mark
  the remaining transitions as un-captured. (Chrome 63+ allows multiple *remote* CDP
  websocket clients on one target, but that is separate from the extension `chrome.debugger`
  API, which still yields to DevTools per the doc above.)
- **One attach per (extension, tab).** `attach` rejects if that extension is already
  attached to the target. Multiple *different* extensions can each attach to the same tab
  (Chrome 63+), but plan the recorder around a single owned attachment per tab for its
  lifetime.
- **Protocol-version pinning.** Attach with an explicit `requiredVersion` (`"1.3"`); a
  mismatch rejects —
  https://developer.chrome.com/docs/extensions/reference/api/debugger/#method-attach

---

## 4. Screenshots

### 4.1 `chrome.tabs.captureVisibleTab`

- **Captures**: "the visible area of the currently active tab" — **viewport only**, no
  scrolled-past content —
  https://developer.chrome.com/docs/extensions/reference/api/tabs/#method-captureVisibleTab
- **Permissions**: "the extension must have either the `<all_urls>` permission or the
  `activeTab` permission" (same URL). The extension has `activeTab` but **not** `<all_urls>`;
  `activeTab` covers the tab the user just acted on, which fits the guided-session model
  (Mike clicks "Start supervised application"). `activeTab` also uniquely allows capturing
  otherwise-restricted `chrome:`, other-extension, and `data:` pages —
  https://developer.chrome.com/docs/extensions/develop/concepts/activeTab
- **Rate limit**: `MAX_CAPTURE_VISIBLE_TAB_CALLS_PER_SECOND = 2` — "captureVisibleTab is
  expensive and should not be called too often" (same URL). One screenshot per meaningful
  transition is well within this; a burst of rapid transitions is not — debounce.
- **Format**: `ImageDetails` — `format` (`"jpeg"`/`"png"`), `quality` (jpeg) —
  https://developer.chrome.com/docs/extensions/reference/api/tabs/#type-ImageDetails
- **No install warning**: `activeTab` shows no permission warning at install —
  https://developer.chrome.com/docs/extensions/develop/concepts/activeTab

### 4.2 Full-page via CDP `Page.captureScreenshot`

- Params: `format`, `quality`, `clip` (a `Viewport`: `x, y, width, height, scale`),
  `captureBeyondViewport` ("Capture the screenshot beyond the viewport. Defaults to false"),
  `fromSurface`, `optimizeForSpeed` —
  https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-captureScreenshot
- Full-page recipe: `Page.getLayoutMetrics` → `cssContentSize` ("Size of scrollable area in
  CSS pixels") —
  https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-getLayoutMetrics —
  then `captureScreenshot({ captureBeyondViewport: true, clip: { x:0, y:0, width, height,
  scale:1 } })`.
- Returns `data` — base64 image (same captureScreenshot URL).
- **Cost**: requires `chrome.debugger` attached — i.e. the banner and the DevTools-coexist
  caveat from §3.4. **If the recorder is already attached for response bodies, full-page
  screenshots come at no additional permission cost** and are strictly better than
  `captureVisibleTab`.

---

## 5. Manifest permissions and trust footprint

| Capability | Manifest cost | Install-time warning | Widens footprint? |
|---|---|---|---|
| Serialize light + open shadow DOM (content script) | host permission for each matched site (already held) | none beyond existing host list | no (already there) |
| MAIN-world `document_start` script for closed shadow roots | `scripting` + host perms, or manifest `content_scripts` with `world:"MAIN"` | none | marginal |
| `captureVisibleTab` | `activeTab` (held) or `<all_urls>` | `activeTab`: **none**; `<all_urls>`: "Read and change all your data on all websites" | `activeTab` no; `<all_urls>` **yes** |
| Response bodies + full-page screenshot + computed-style snapshot (CDP) | **`debugger`** (held) | **"Access the page debugger backend"** + **"Read and change all your data on all websites"** | **yes — the big one** |
| `webRequest` event feed (timing only) | `webRequest` + host perms | historically "Read your browsing activity" class; no body access gained | modest, and low value here |
| `declarativeNetRequest` | `declarativeNetRequest` (+ `declarativeNetRequestFeedback`, unpacked-only, for match debug) | limited | low — but gives no capture ability |

Primary sources for the warnings:
`debugger` → "Access the page debugger backend" —
https://developer.chrome.com/docs/extensions/reference/permissions-list ; broad-host and
`debugger` also trigger "Read and change all your data on all websites" —
https://developer.chrome.com/docs/extensions/develop/concepts/declare-permissions#permissions-with-warnings
Debugger's extra power (sidesteps host permissions / file access) —
https://chromium.googlesource.com/chromium/src/+/main/extensions/docs/security_faq.md

**Reading**: the extension **already** carries the two permissions that matter (`activeTab`,
`debugger`) and a wide `host_permissions` list. The raw-capture design does **not** need to
add `<all_urls>` (keep relying on `activeTab` + the named host list) and does **not** need
`webRequest`. The only genuinely new surface would be a `document_start` MAIN-world script,
which is cheap. So the datalake raw layer adds **near-zero** incremental trust cost over
what's already installed — the cost was already paid when `debugger` went into the manifest.

---

## 6. Unpacked / developer-mode and the `debugger` permission

- **No absolute Chrome ban.** `debugger` is a documented, shippable permission. But Chrome
  Web Store program policy requires "the narrowest permissions necessary" and
  "request … those with the least access" when alternatives exist —
  https://developer.chrome.com/docs/webstore/program-policies/policies — and CWS review
  treats `debugger` as high-scrutiny because of its power
  (https://chromium.googlesource.com/chromium/src/+/main/extensions/docs/security_faq.md).
  Extensions that do ship it (automation/testing toolkits) accept the scary dual warning and
  slow review.
- **One capability is unpacked-only by rule**: `chrome.declarativeNetRequest.onRuleMatchedDebug`
  requires `declarativeNetRequestFeedback` and works "only for unpacked extensions" —
  https://developer.chrome.com/docs/extensions/reference/api/declarativeNetRequest#event-onRuleMatchedDebug
- **Banner suppression is a dev-only affordance**: `--silent-debugger-extension-api` and
  enterprise-policy install are the only ways to hide the debugging banner
  (`kSilentDebuggerExtensionAPI` in Chromium `chrome/common/chrome_switches.cc`).
  A store build for other users cannot assume either.
- **Dev-mode friction that ships with unpacked**: Chrome nags "Disable developer mode
  extensions" on some startups, and enterprise policy `ExtensionDeveloperModeSettings` /
  runtime-blocked-hosts can disable dev mode or the debugger API outright
  (https://chromium.googlesource.com/chromium/src/+/main/extensions/docs/security_faq.md
  notes debugger "is entirely disabled if runtime-blocked hosts are configured by enterprise
  policy").
- **Loading unpacked is explicitly "not a security bug"** — Chromium compares it to
  "persuading the user to open devtools and paste code" (security FAQ, same URL). It is the
  right distribution model for a personal power-tool that needs `debugger`.

**Conclusion**: wwworkremote is a single-user, unpacked, dev-mode tool by design. It can and
does hold `debugger`. A hypothetical Chrome Web Store version of this extension should
**not** ship `debugger` — it would strip response-body and full-page-screenshot capture and
fall back to `captureVisibleTab` + content-script DOM only. That divergence is fine because
there is no plan to ship to the store; but the raw-capture seam should be built so the
`debugger`-dependent captures are **individually optional** and degrade cleanly if absent.

---

## 7. Implications for the raw-capture seam (TASK-122)

**Viable now, low marginal cost:**

1. **Per-transition DOM snapshot from the content script** — `documentElement.getHTML({
   serializableShadowRoots: true, shadowRoots: <collected open roots> })`, one artifact per
   injected frame, stitched by frame id in the manifest. Cheap, no new permission. Accept
   that cross-origin frames and closed shadow roots are gaps; record which frames were
   un-capturable rather than silently dropping them.
2. **Full HAR incl. response bodies via `chrome.debugger` + CDP `Network`** — attach once at
   session start, `Network.enable` with enlarged buffers, prefer
   `Network.streamResourceContent` on `responseReceived` to beat buffer eviction, pull
   `getResponseBody` / `getRequestPostData` keyed by `requestId`. Reuse the existing
   `debugger` permission. Handle `onDetach` (DevTools opened / user hit Cancel) by marking
   the rest of the session partially-captured and optionally re-attaching.
3. **Full-page screenshot via CDP `Page.captureScreenshot`** in the *same* debugger session
   (`captureBeyondViewport:true`, `clip` from `Page.getLayoutMetrics.cssContentSize`).
   Strictly better than `captureVisibleTab`; only used when already attached.
4. **`captureVisibleTab` as the no-debugger fallback** for the screenshot slot — viewport
   only, debounced to ≤2/sec, `activeTab`-gated.
5. **Computed styles**, if wanted for fidelity, via CDP `DOMSnapshot.captureSnapshot` with a
   style whitelist — one call, not a tree walk — again in the same debugger session.

**Defer / drop:**

- **Closed shadow DOM capture** — drop for v1. Revisit only if a spot-check shows a target
  ATS (Workday, some Greenhouse embeds) puts application fields inside closed roots; if so it
  needs a `document_start` `world:"MAIN"` `attachShadow` shim, a separate small task.
- **Content-script resource inliner** (fetch + data-URI every CSS/image/font) — drop.
  CSP-limited, slow, huge artifacts. Get resource bodies from CDP if a self-contained
  snapshot is truly needed; otherwise store the raw HTML + the HAR and reconstruct on read.
- **`chrome.webRequest`** — do not add. At most, use it (no new manifest entry beyond
  `webRequest`) as a timing signal for *when* to pull a CDP body, and only if CDP's own
  `Network` events prove insufficient (they should not).
- **`<all_urls>`** — do not add. `activeTab` + the named host list already cover the guided
  flow and avoid the "all websites" install warning.
- **Banner suppression in the product** — out of scope. On Mike's machine, launch Chrome
  with `--silent-debugger-extension-api` if the banner is annoying during dogfooding
  (TASK-112); do not design around hiding it.

**Net**: the greedy raw-asset scope the map decided on (DOM per transition + full HAR with
bodies + screenshot per transition) is **achievable today** with the permissions the
extension already has. The one unavoidable UX tax is the `chrome.debugger` banner and its
surrender to DevTools; the seam design must treat debugger-sourced captures as optional and
record capture gaps explicitly in `manifest.json`.
