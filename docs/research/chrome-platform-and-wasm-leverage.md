# Chrome platform capabilities & WebAssembly: where this project can lean harder

**Doc location note.** `docs/research/` has no prior convention — its only neighbour is
`chrome-built-in-ai-flags.md` (created the same session, 2026-08-28). The closest older
neighbours are the design docs in `docs/architecture/`, but those describe *this system*;
this file is external-technology reconnaissance feeding decisions on TASK-102 / TASK-104 /
TASK-105 / TASK-108 / TASK-112 and the hashed-CSS selector problem. If it stays a one-off,
fold it into `docs/architecture/` later.

**Scope.** Chrome built-in AI APIs (Prompt/Summarizer/Writer/Rewriter/Proofreader/Classifier/
Semantic Embedder), WebNN, WebMCP, and Autofill AI are covered by the sibling doc
`chrome-built-in-ai-flags.md` — **not repeated here**. This doc covers the *WASM* route to
on-device inference, plus non-AI Chrome platform capabilities.

---

## 1. Bottom line

The single highest-leverage move is **`chrome.debugger` + the Chrome DevTools Protocol from
inside the existing extension**: the Accessibility, DOMSnapshot, Network, Page and
Input CDP domains give the guided-session recorder (TASK-112) and the automatic-walkthrough
driver (TASK-105) selector-free field identification, full-fidelity page snapshots, XHR/JSON
response-body capture that `declarativeNetRequest` structurally cannot do, and synthetic input —
i.e. most of what a headless browser offers, *while still being the real extension in Mike's real
logged-in session*. That directly answers TASK-105's "headless vs real extension" question and
attacks the brittle-hashed-CSS problem that `extension/content.js` (120 KB, mostly per-provider
selector rules with comments documenting repeated LinkedIn/Workday/Greenhouse breakage) exists to
fight. WASM-based on-device inference (transformers.js + a ~23 MB quantized MiniLM in an Offscreen
Document) is a credible, flag-free way to do TASK-108's first-pass field classification and
extension-side dedup/prerank, but it is a prototype, not a commitment. A single shared Rust→WASM
core for scoring/extraction is architecturally tidy but too heavy for a solo maintainer right now —
the real duplication today (provider URL/identity regexes in `Scenarios::Capture::PATTERNS` vs
`content.js` `PROVIDERS`) is better solved by a shared JSON data file than a WASM binary. Isolated
Web Apps + Controlled Frame are a real alternative harness architecture but lose Mike's
authenticated session (separate storage partition) and can't be distributed to one Mac without
enterprise/ChromeOS — watch, don't build.

---

## 2. Ranked shortlist

| # | Capability | Repo task it serves | What it replaces / unblocks | Effort | Recommendation |
|---|---|---|---|---|---|
| 1 | **`chrome.debugger` → CDP: `Accessibility.getFullAXTree`, `DOMSnapshot.captureSnapshot`, `Page.captureSnapshot`** | TASK-112, TASK-105, TASK-102, hashed-CSS selector churn in `content.js` | Selector-free field/scenario-signature capture; replaces guessing at `.css-129m7dg`-style hashed classes | M | **Prototype** (adopt if it holds up) |
| 2 | **`chrome.debugger` → CDP: `Network` domain** (`Network.getResponseBody`, `Fetch`) | TASK-102 `Scenarios::Capture` (reads `ats_application_id` from JSON response bodies), TASK-83 Greenhouse `applications.json` | Capturing ATS XHR/JSON responses — `declarativeNetRequest`/MV3 `webRequest` **cannot** read response bodies | M | **Prototype** (bundle with #1) |
| 3 | **`chrome.debugger` → CDP: `Input` domain** as the Phase A walkthrough driver | TASK-105 (the open "headless vs real extension" question) | A real-extension driver with headless-browser-like control; keeps provider recognition + extraction + capture in one process | M | **Prototype** (bundle with #1) |
| 4 | **Offscreen Documents API** (`chrome.offscreen`, `DOM_PARSER`/`BLOBS`/`WORKERS`) | Prereq for #5; heavier correlation off the service worker | Moves DOM parsing / WASM / HAR assembly out of the ephemeral MV3 service worker | S | **Adopt** (when #5 or heavy correlation lands) |
| 5 | **WASM on-device inference** — transformers.js v3 + `all-MiniLM-L6-v2` (int8) in the offscreen doc | TASK-108 (first-pass field classification), extension-side dedup/prerank feeding TASK-32.x | A flag-free alternative to Gemini Nano for cheap classification; keeps some load off `LLM::Orchestrator` with zero network round-trip | M | **Prototype** |
| 6 | **OPFS** (`navigator.storage.getDirectory`) in the offscreen doc for capture blobs | TASK-102 capture storage, TASK-112 session evidence | HAR/MHTML-shaped blobs that blow past `chrome.storage.session`'s ~10 MB; sync access handles in a worker | S | **Adopt** (with #1) |
| 7 | **`@puppeteer/replay` JSON schema** as the guided-session step format | TASK-112 AC#5 (replay deterministic steps) | A documented, tooling-backed replay format instead of a bespoke one; the repo already has `devtools.html`/`devtools.js` stubs | S | **Watch / prototype** |
| 8 | **Shared Rust→WASM classification core** (job-fit heuristics, ATS extraction rules, US-only location classification) | `docs/agents/interop.md` single-authority principle | One artifact in extension + Rails (`wasmtime-rb`) + other on-box tools | L | **Watch** (start with a shared JSON rules file) |
| 9 | **Isolated Web App + `<controlledframe>` + Direct Sockets** as harness host | TASK-104 / TASK-105 (sandbox harness only) | Full script-injection + network interception into cross-origin ATS pages in one app you own | L | **Watch** — skip for TASK-112 (session-partition loss) |
| 10 | **WASM threads** (`cross_origin_embedder_policy`/`opener_policy` manifest keys) | Only if MiniLM single-thread inference is too slow | Multi-threaded ONNX Runtime Web | M | **Skip** — SIMD alone is enough; COEP `require-corp` risks breaking other extension fetches |
| 11 | **WebGPU LLMs in the extension** (web-llm / WebLLM, MLC) | — | Larger on-device models | L | **Skip** — hundreds of MB to GB download; Gemini Nano (sibling doc) already covers the LLM tier |

---

## 3. Thread A — WASM as a shared extraction / scoring core

### What's actually duplicated today

The repo's stated principle is "don't re-implement scoring / extraction in a second place"
(`docs/agents/interop.md`; `bin/wwwr match` is the one entry point). In practice:

- **Job-fit scoring is an LLM call**, not a heuristic — `LLM::ProfileMatcher.call`
  (`app/services/LLM/profile_matcher.rb`), reached via `Wwwr::Interop` (`lib/wwwr/interop.rb`).
  There is nothing portable to compile: the "core" is a prompt plus `ruby_llm`. WASM does not
  help here.
- **Deterministic classification *is* duplicated.** `Scenarios::Capture::PATTERNS`
  (`app/services/scenarios/capture.rb`) is a Ruby regex table mapping each provider to its
  identity-extraction patterns (`linkedin` → `%r{/jobs/view/(\d+)}`, etc.). `extension/content.js`
  `PROVIDERS` holds the parallel `match:`/`readySelector`/`extract()` knowledge in JS. Date parsing
  is implemented a third time in `content.js`. The `Scenarios::Capture` file even carries a
  `ponytail:` comment admitting the patterns are "inferred from this codebase's existing
  RowImporter field/URL knowledge."
- **US-only location classification** lives in `Geo::CommuteZone` (`app/services/geo/commute_zone.rb`)
  and `Geo::GeoipClient` — Rails-only, and the `remote?` check reads `@job_posting.data` keys that
  only exist post-ingestion. The extension has no equivalent.

### Is a single Rust→WASM core realistic?

**Toolchain (all mature):**

- Rust → `wasm32-unknown-unknown` with **`wasm-bindgen`** (JS glue) or **`wasm-pack`** (bundler
  packaging) is the standard browser path.
- Rust → **WASI 0.2 / Component Model** with **`cargo component`** + **`jco`** (JS host) is the
  portable-across-runtimes path. WASI 0.2 and the Component Model shipped in Wasmtime as the
  reference implementation in late 2024
  ([component-model.bytecodealliance.org](https://component-model.bytecodealliance.org/running-components/wasmtime.html)).
- Ruby host: **`wasmtime-rb`** is the official Bytecode Alliance gem — a Rust-based native
  extension, precompiled gems for macOS/Linux/Windows, Ruby ≥ 3.1
  ([github.com/bytecodealliance/wasmtime-rb](https://github.com/bytecodealliance/wasmtime-rb),
  [bytecodealliance.org — Using Wasmtime from Ruby](https://bytecodealliance.org/articles/using-wasmtime-from-ruby)).
  It supports the component model and WASI 0.2.

**What breaks / what it costs:**

1. **MV3 CSP.** Extension pages (service worker, offscreen document, side panel) run under a
   locked minimum CSP: `script-src 'self' 'wasm-unsafe-eval'; object-src 'self';` — you cannot
   relax it, and `'wasm-unsafe-eval'` is already included, so `WebAssembly.instantiate()` from a
   bundled `.wasm` works out of the box
   ([developer.chrome.com — Manifest CSP](https://developer.chrome.com/docs/extensions/reference/manifest/content-security-policy)).
   **Content scripts are the exception** — they execute in an isolated world but WASM
   instantiation there has historically been unreliable and is subject to the *host page's* CSP;
   the clean answer is to run WASM in an **offscreen document** (Thread C), not the content
   script.
2. **Two runtimes, two failure modes.** A native `wasmtime-rb` gem adds a compiled dependency to
   the Rails app (deploy + CI cost) for a payoff that today is ~3 small pure functions.
3. **The lazy alternative wins now.** The genuinely shared thing is *data* — provider URL
   patterns, signature expectations (`Scenarios::HandshakeCheck::SIGNATURE_EXPECTATIONS`),
   role-family taxonomy (`app/services/role_family.rb`, TASK-32.3 already calls it a "shared data
   artifact"). A committed JSON/YAML file consumed by both Ruby and `content.js` removes the
   duplication with none of the toolchain. Revisit a WASM core only if the *logic* (not the data)
   starts diverging in a way that causes real bugs.

**Verdict: Watch.** Ship a shared rules data file first (S). A Rust→WASM core is a real option
if extension-side and server-side classification logic later diverge materially, but it is an
L-effort answer to an S-effort problem today.

---

## 4. Thread B — WASM-based on-device inference (the flag-free route)

### The libraries

| Library | Backend | Fit here |
|---|---|---|
| **transformers.js v3** (Hugging Face) | ONNX Runtime Web (WASM + WebGPU) | Best fit: sentence embeddings + zero-shot classification, one API ([huggingface.co/blog/transformersjs-v3](https://www.huggingface.co/blog/transformersjs-v3)) |
| **ONNX Runtime Web** | WASM (SIMD, threads) / WebGPU | The layer transformers.js sits on; use directly only if you need a custom model |
| **wllama** | Pure WASM (llama.cpp), no WebGPU | Tiny GGUF LLMs / embeddings with no WebGPU dependency; slower |
| **web-llm / WebLLM** (MLC) | WebGPU only | 1B–8B chat models; **skip** — hundreds of MB to GB downloads; Gemini Nano covers this tier per the sibling doc |

### The jobs it would serve

- **Extension-side dedup / prerank** before a posting is sent to Rails — embed the posting text
  and compare to recently-seen postings. Feeds, but does **not** replace, TASK-32.7 (which is
  explicitly server-side `pgvector`/`neighbor` and says "Do not add a new embedding provider").
- **Zero-shot classification**: US-vs-non-US location (the hard-drop constraint), relevance triage,
  "is this field a work-authorization / demographic / free-text question" — TASK-108's first-pass
  sense-making, as the flag-free alternative to the Prompt API.
- **Short summarization** of long descriptions before display — lower priority.

### Numbers (all-MiniLM-L6-v2, the standard small embedder)

- **~22 M params**, int8-quantized ONNX ≈ **~23 MB** on disk; ~75% smaller than fp32, ">95%
  embedding similarity" retained
  ([huggingface.co/Ayeshas21/...-quantized](https://huggingface.co/Ayeshas21/sentence-transformers-all-MiniLM-L6-v2-quantized)).
- **~8–12 ms per embedding on the WASM backend** (M2 MacBook Air); WebGPU ≈ 32 ms for a single
  512-token input vs ~378 ms WASM at that sequence length — WebGPU only pulls ahead at batch size
  / long sequences
  ([huggingface.co/spaces/Xenova/webgpu-embedding-benchmark](https://huggingface.co/spaces/Xenova/webgpu-embedding-benchmark/discussions/3),
  [sitepoint.com — WebGPU vs WebASM](https://www.sitepoint.com/webgpu-vs-webasm-transformers-js/)).
- Cold start = model download (one-time, cache in OPFS) + WASM compile; budget a few hundred ms
  to low seconds on first run, near-instant after.

### MV3 mechanics

- **Bundle everything.** transformers.js fetches ONNX + WASM helper files at runtime by default;
  MV3 CSP blocks that. Bundle the `.wasm`/`.onnx` files, set `env.localModelPath` /
  `env.backends.onnx.wasm.wasmPaths` to the bundled path, and list them under
  `web_accessible_resources`
  ([Medium — Transformers.js inside a Chrome extension (MV3)](https://medium.com/@vprprudhvi/running-transformers-js-inside-a-chrome-extension-manifest-v3-a-practical-patch-d7ce4d6a0eac)).
- **Run it in an Offscreen Document, not the service worker.** ONNX Runtime Web's WASM/WebGPU
  backends have been unavailable or flaky inside MV3 service workers
  ([microsoft/onnxruntime#20876](https://github.com/microsoft/onnxruntime/issues/20876),
  [huggingface/transformers.js#787](https://github.com/xenova/transformers.js/issues/787)).
  WebGPU was later exposed to service workers, but the offscreen document is still the safe host
  and matches `sandbox-provider.md`'s own "offscreen document" suggestion.
- **Threads need cross-origin isolation; SIMD does not.** WASM SIMD is stable in Chrome and needs
  no headers. WASM threads / `SharedArrayBuffer` require the extension to set
  `"cross_origin_embedder_policy": {"value": "require-corp"}` and
  `"cross_origin_opener_policy": {"value": "same-origin"}` in the manifest — and even then
  **service workers are not cross-origin isolated**; extension *pages* (offscreen doc, side panel)
  are ([developer.chrome.com — Cross-origin isolation](https://developer.chrome.com/docs/extensions/develop/concepts/cross-origin-isolation)).
  `require-corp` can break the extension's other cross-origin `fetch()`es (to the Rails API, to
  `just3ws.localhost`) unless every response carries CORP headers. **Recommendation: run MiniLM
  single-thread + SIMD, skip threads**, revisit only if latency is a measured problem.

### Relevant WASM feature status (Chrome)

| Feature | Chrome | Notes |
|---|---|---|
| Fixed-width SIMD | Stable (Chrome 91+) | Needed by ONNX Runtime Web; no flag |
| **Relaxed SIMD** | Stable (Chrome 114) | Adds dot-product / FMA instructions, **1.5–3× on existing ML workloads** ([developer.chrome.com — WASM/WebGPU for Web AI pt.1](https://developer.chrome.com/blog/io24-webassembly-webgpu-1)) |
| Threads / atomics | Stable, gated on cross-origin isolation | See above |
| **Memory64** | Stable (Chrome ~133, part of "Wasm 3.0") | Lifts the 4 GB heap cap; not needed for MiniLM, matters only for larger models ([Intent to Ship: Memory64](https://groups.google.com/a/chromium.org/g/blink-dev/c/5vTbd1dttwc)) |
| **JS Promise Integration (JSPI)** | Phase 4 (2026); origin-trial→stabilizing | Lets sync WASM `await` async JS without Asyncify's code-size cost; nice-to-have, not required |

**Verdict: Prototype** against the sandbox provider (TASK-104), exactly as TASK-108 AC#2 asks.
Single embedder model, offscreen document, SIMD only. Decision gate: does on-device classification
of one real field case beat just calling Rails, on latency *and* accuracy?

---

## 5. Thread C — Chrome platform capabilities for the recorder & walkthrough driver

This is the strongest cluster. The extension currently declares only
`["activeTab", "scripting", "storage", "sidePanel"]` — no `debugger`, no `offscreen`, no
`webRequest`/`declarativeNetRequest`.

### 5.1 `chrome.debugger` + CDP — the headless-vs-real-extension answer

`chrome.debugger` attaches the extension as a CDP client to a tab (needs the `"debugger"`
manifest permission; shows a persistent "extension is debugging this browser" infobar). It exposes
a **restricted but large** set of CDP domains:
`Accessibility, Audits, CacheStorage, Console, CSS, Database, Debugger, DOM, DOMDebugger,
DOMSnapshot, Emulation, Fetch, IO, Input, Inspector, Log, Network, Overlay, Page, Performance,
Profiler, Runtime, Storage, Target, Tracing, WebAudio, WebAuthn`
([developer.chrome.com — chrome.debugger](https://developer.chrome.com/docs/extensions/reference/api/debugger)).

TASK-105's open question ("headless browser like Capybara/Cuprite, or the real extension?") was
resolved *in favour of the real extension* (task comments, commit `735c72e6`), but the
implementation notes record it getting stuck on flaky content-script injection. CDP closes that
gap: `Page.navigate` + `Input.dispatchKeyEvent`/`dispatchMouseEvent` + `Runtime.evaluate` give the
real extension the same drive-the-page control a headless browser has, without a second browser
process and without depending on content-script injection timing. `docs/architecture/sandbox-provider.md`
open question #1 can be answered: **real extension + `chrome.debugger` for the driver**, Cuprite
stays as the lower-level deterministic fixture-test fallback.

Risks / costs:

- The infobar is unavoidable and cannot be suppressed (Chrome anti-abuse). Acceptable for a
  single-user dogfood tool; a blocker for Web Store distribution — irrelevant here since the
  extension is loaded unpacked (`IS_LOCAL_BUILD` gate in `content.js`).
- Only one CDP client per tab — if Mike opens DevTools on the driven tab, the extension detaches.
- Cannot attach to `chrome://` pages or the Web Store.
- `"debugger"` is a high-alarm permission in review; again, moot for an unpacked local build.

### 5.2 Selector-free field & signature capture — the direct answer to hashed CSS

`extension/content.js` is one long testament to hashed-CSS-module churn: LinkedIn moved to
"fully hashed/obfuscated CSS" (comment ~line 128), Workday `.css-129m7dg` "a hashed CSS-module
class, inherently unstable" (~line 342), Greenhouse/Ashby/SmartRecruiters selectors "turned out
to be" wrong. Two CDP snapshots sidestep selectors entirely:

- **`Accessibility.getFullAXTree`** — the computed accessibility tree: every form field with its
  accessible *name* (the visible label), *role* (`textbox`, `combobox`, `checkbox`), required
  state, and value. A "Work authorization" `<select>` is identifiable by its label + role
  regardless of what its class attribute is this week. This is a far more stable key for
  `ApplicationFieldMapping` / `ApplicationFieldObservation` than a CSS selector.
- **`DOMSnapshot.captureSnapshot`** — DOM + layout + computed style + text for the whole document
  in one call, with string-table deduplication
  ([chromedevtools.github.io — DOMSnapshot](https://chromedevtools.github.io/devtools-protocol/tot/DOMSnapshot/)).
  A complete, replayable structural record for a `ScenarioSignature` capture — you can re-derive
  any signature later without having re-run the site.
- **`Page.captureSnapshot`** (MHTML) — single-file archive of the rendered page, images inlined.
  Ideal durable evidence for a `Scenario` row; `Scenarios::Capture` already accepts "a HAR or DOM
  capture."

This maps onto `Panoramic View` / `Signature Registry`: the accessibility tree gives a
provider-independent field identity; the DOM snapshot is the raw material `Scenarios::HandshakeCheck`
diffs against a Reference Scenario.

### 5.3 Capturing ATS XHR/JSON — CDP `Network`, because DNR can't

`Scenarios::Capture` explicitly reads `ats_application_id` "in a JSON response body," and TASK-83
wants the Greenhouse `my.greenhouse.io/applications.json` payload (MEMORY notes it aggregates
across all tenants with exact `applied_at` timestamps). **Neither `declarativeNetRequest` nor MV3
`webRequest` can read response bodies** — DNR is declarative-only, and MV3 removed blocking
`webRequest` for non-enterprise extensions
([developer.chrome.com — Replace blocking web request listeners](https://developer.chrome.com/docs/extensions/develop/migrate/blocking-web-requests)).
The standard workaround is CDP: enable the `Network` domain and call `Network.getResponseBody`
(or intercept via the `Fetch` domain)
([chromium-extensions thread](https://groups.google.com/a/chromium.org/g/chromium-extensions/c/MPCKIx2Rgv8)).
Since Thread C already pulls in `chrome.debugger`, this is free.

### 5.4 Offscreen Documents API

`chrome.offscreen` (Chrome 109+, `"offscreen"` permission) runs a hidden DOM page for work the
service worker can't do — `DOM_PARSER`, `DOM_SCRAPING`, `BLOBS`, `WORKERS`
([developer.chrome.com — chrome.offscreen](https://developer.chrome.com/docs/extensions/reference/api/offscreen)).
Use it for: assembling HAR/MHTML blobs, parsing captured DOM, and hosting the Thread B WASM
model. Constraint: **exactly one offscreen document per extension at a time** — so it becomes a
small multiplexed worker host, not one-per-task.

### 5.5 Storage for captures

| Option | Cap | Fit |
|---|---|---|
| `chrome.storage.session` (used today for extracted data) | ~10 MB | Too small for MHTML/HAR blobs |
| `chrome.storage.local` | ~10 MB default (unlimited with `unlimitedStorage`) | OK for small JSON, not blobs |
| **IndexedDB** | Large, quota-based | Fine; structured records |
| **OPFS** (`navigator.storage.getDirectory`) | Quota-based, `navigator.storage.estimate()` | **Best for HAR/MHTML blobs** — byte-level access, synchronous `FileSystemSyncAccessHandle` in a worker, no per-file permission prompt ([web.dev — OPFS](https://web.dev/articles/origin-private-file-system)) |

Recommendation: OPFS in the offscreen doc for capture blobs; keep small metadata in IndexedDB or
`chrome.storage`.

### 5.6 File System Access API for exports

`showSaveFilePicker()` from an extension **page** (side panel / offscreen, not the service
worker) can write a capture/replay bundle to disk for Mike to inspect or hand to another tool.
Needs a user gesture. Low effort, nice for debugging; not on the critical path since captures
already POST to the local Rails API.

### 5.7 DevTools Recorder panel

The built-in Recorder exports to **JSON, `@puppeteer/replay`, and Puppeteer**, and third parties
extend it via `chrome.devtools.recorder`
([developer.chrome.com — Recorder reference](https://developer.chrome.com/docs/devtools/recorder/reference),
[developer.chrome.com — Extend Recorder](https://developer.chrome.com/blog/extend-recorder)).
The repo already has `extension/devtools.html` + `devtools.js` stubs. **Reuse value is the
`@puppeteer/replay` step schema**, not the panel: adopting that JSON shape for `GuidedSessionEvent`
step sequences gives TASK-112 AC#5 ("replay deterministic steps") a documented, tooling-backed
format and a ready `@puppeteer/replay` runner, instead of inventing a replay format. The panel
itself records generic user flows and doesn't know about pump-track phases or approval gates, so
it isn't a drop-in recorder.

---

## 6. Thread D — Isolated Web Apps + Controlled Frame as a harness host

### What it would give you

An **IWA** is a bundled, signed (`.swbn`, Ed25519/ECDSA-P256), versioned app on an
`isolated-app://` origin with mandatory cross-origin isolation
(`COOP: same-origin` + `COEP: require-corp` + `CORP: same-origin`)
([developer.chrome.com — IWA introduction](https://developer.chrome.com/docs/iwa/introduction)).
That isolation unlocks high-trust APIs:

- **`<controlledframe>`** — like `<webview>` for IWAs: `executeScript()` / `insertCSS()` into
  cross-origin third-party content, `WebRequest` observation/modification of the embedded page's
  traffic, and it **loads pages that set `X-Frame-Options`/frame-ancestors CSP** (which a normal
  iframe cannot) ([developer.chrome.com — Controlled Frame](https://developer.chrome.com/docs/iwa/controlled-frame)).
- **Direct Sockets** — raw TCP/UDP to the Rails backend with no CORS/relay
  ([developer.chrome.com — Direct Sockets](https://developer.chrome.com/docs/iwa/direct-sockets)).

On paper this replaces the content-script + `chrome.debugger` combo with one app you fully
control, and Mike's `chrome://flags` already has the IWA family enabled.

### Why it's watch-not-build

1. **Session partition loss — decisive for TASK-112.** A `<controlledframe>` runs in the IWA's
   own storage partition, not Mike's browsing profile. Guided runs against *real* live ATS pages
   depend on Mike already being logged into LinkedIn / Workday / Greenhouse — the whole point of
   "the real extension in the real session." Inside a Controlled Frame he'd have to re-authenticate
   to every ATS. (For the *sandbox* provider, TASK-104/105, there's no login, so this doesn't
   bite — an IWA harness is viable there specifically.)
2. **Distribution.** IWA production install is "only available to Chrome Enterprise administered
   ChromeOS devices" in the initial release
   ([developer.chrome.com — IWA introduction](https://developer.chrome.com/docs/iwa/introduction)).
   For one macOS machine it's **dev-mode only**: `chrome://flags#enable-isolated-web-app-dev-mode`
   plus `chrome://web-app-internals` with a dev-mode proxy or a self-signed `.swbn`
   ([chromeos.dev — Enable IWA developer mode](https://chromeos.dev/en/tutorials/getting-started-with-isolated-web-apps/1)).
   Workable for Mike-only, but it's a parallel install/build/signing pipeline to maintain.
3. **Rebuild cost.** `content.js` (120 KB of provider knowledge), `background.js`, `sidepanel.js`,
   the guided-session correlation, and the `?wwwr_id=` / `?guided_session_token=` entry flow all
   move into a new app shell. Large L-effort for a system that already works.
4. **What genuinely gets simpler:** cross-origin isolation is free (WASM threads for Thread B
   with no manifest gymnastics), network interception of the embedded page is first-class, and
   there's no MV3 service-worker lifecycle to fight.

**Verdict: Watch.** If a *dedicated sandbox-harness* app (TASK-104/105, no real logins) is ever
built separately from the production extension, an IWA + `<controlledframe>` + Direct Sockets is
the right shape for it. Don't rebuild the shipping extension as an IWA.

---

## 7. Thread E — Other capabilities considered

| Capability | Verdict | Reason |
|---|---|---|
| `navigator.userActivation` | **Minor adopt** | Could harden the "final submit requires a real user gesture" invariant in `guided-session-flow.md` — check `navigator.userActivation.isActive` before allowing an approved submission to proceed. Small, defensive, worth a line of code. |
| `scheduler.postTask()` / `scheduler.yield()` | **Skip** | Could chunk the long `content.js` extraction chain to avoid jank, but extraction runs once per page load and isn't a reported pain point. YAGNI. |
| User-Agent Client Hints | **Skip** | No use — the extension isn't doing UA-based content negotiation. |
| Storage Buckets API | **Skip** | Eviction-priority buckets solve a problem this single-user local tool doesn't have. |
| Background Fetch | **Skip** | For large resumable downloads; nothing here downloads at that scale (the MiniLM model is a one-time ~23 MB, fine as a normal fetch). |
| `chrome.offscreen` `AUDIO_PLAYBACK` | **Skip** | No audio. |
| WebCodecs / WebTransport | **Skip** | No media, no streaming transport need. |
| WebGPU (directly, not via a lib) | **Skip for now** | Only worth it if Thread B's WASM inference is measured too slow; MiniLM on WASM+SIMD is ~10 ms/embedding. |

---

## 8. If you do one thing

**Prototype `chrome.debugger` + CDP inside the existing extension**, targeting the sandbox
provider (TASK-104). Concretely: add the `"debugger"` permission to a *local-build-only* manifest,
attach on guided-session start, and capture `Accessibility.getFullAXTree` +
`DOMSnapshot.captureSnapshot` + `Page.captureSnapshot` at each pump-track phase transition, plus
`Network.getResponseBody` for the fake `applications.json`. Feed all of it through the existing
`Scenarios::Capture` path. This one change answers TASK-105's driver question, gives TASK-112 a
selector-free recorder, and directly retires the hashed-CSS guessing game in `content.js` for the
guided-session use case (the free-browsing enrichment path can keep its selector chain).

## 9. If you do three things

1. **The above** — `chrome.debugger` / CDP capture (Accessibility + DOMSnapshot + Page + Network).
2. **Add an Offscreen Document and prototype WASM on-device classification** (transformers.js v3
   + int8 `all-MiniLM-L6-v2`, SIMD only, no threads) for TASK-108's first-pass field
   classification and extension-side dedup/prerank. Decision gate: beats calling Rails on latency
   and accuracy for at least one real field case.
3. **Store capture blobs in OPFS** (from the offscreen doc) and **adopt the `@puppeteer/replay`
   JSON schema** for `GuidedSessionEvent` step sequences, so TASK-112's replay slice (AC#5) has a
   real format and runner instead of a bespoke one.

Everything else — a shared Rust→WASM core, an IWA harness, WASM threads, WebGPU LLMs — stays on
the watch list until the prototypes above prove out or a concrete pain forces the issue.
