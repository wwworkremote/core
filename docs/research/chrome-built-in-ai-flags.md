# Chrome built-in AI flags: which ones serve this project

**New doc location.** The repo has no prior research-notes convention. The closest
neighbours are the design docs in `docs/architecture/`, but those describe *this system's*
design; this is external-technology reconnaissance feeding a spike (TASK-108). Putting it
under `docs/research/` keeps that distinction visible and gives future primary-source
investigations a home. If this stays a one-off, fold it into `docs/architecture/` later.

Chrome build assessed: **152.0.7977.65, macOS** (Mike's paste, 2026-08-28).
Primary question: **does TASK-108 need Mike to flip any `chrome://flags` at all?**

---

## TL;DR (5 lines)

1. **The MV3 extension needs zero flags for the core path.** Prompt API and Summarizer API
   have been stable *for Chrome Extensions* since Chrome 138; on Chrome 152 they just work.
2. **Only the model-download debug flags are worth turning on**, and only during the spike:
   `#optimization-guide-on-device-model` + `#optimization-guide-debug-logs` to diagnose
   Gemini Nano not downloading.
3. **Classifier API is dead** (explainer archived "no longer pursued", May 2026) and the
   **Semantic Embedder API** is an unshipped design sketch. Neither is a real option now.
4. **Autofill AI and glic/actor flags should stay OFF** during TASK-112 guided-session
   dogfooding — they let *Chrome* write or drive form fields the extension is trying to
   record, corrupting provenance, and some send form context to Google servers.
5. **WebMCP does not replace `bin/wwwr match`** — it is page-to-in-browser-agent only, an
   external CLI can't connect. WebNN is a 2027-horizon fallback, not for now.

---

## Verdict table

| Flag | Plausible use here | Verdict |
|---|---|---|
| `#prompt-api` | On-device first-pass field classification (TASK-108) | **Ignore the flag** — API already stable for extensions; capability = **use now** |
| `#prompt-api-multimodal-input` | Classify a screenshot of an unfamiliar form region | **Evaluate** (extensions already have image input; unclear it beats text) |
| `#prompt-api-sampling-mode` | Deterministic low-temp classification | **Ignore** — extensions already get raw `topK`/`temperature` |
| `#summarizer-api` | TL;DR of long job descriptions; condense screening-question context | **Ignore the flag** (stable); capability = **use now / evaluate** |
| `#summarizer-api-performance-preference` | speed vs quality knob | **Ignore** — already an option on the stable API (`type: "speed"`/`"capability"`) |
| `#writer-api`, `#rewriter-api` | Draft/tidy free-text screening answers on-device instead of round-tripping to `LLM::AnswerGenerator` | **Evaluate** — still developer-trial, quality ceiling; lower priority than Prompt API |
| `#proofreader-api` | Proofread Mike's typed answers mid-session | **Evaluate** (lean ignore) — origin-trial, nice-to-have |
| `#semantic-embedder-api` | On-device embeddings (TASK-32.7 is server-side; extension-side dedupe is the only fit) | **Ignore** — unshipped design sketch, Canary-only; also wrong tier (TASK-32.7 is Rails/pgvector) |
| `#classifier-api` | Field-type classification | **Ignore** — explainer archived "no longer pursued" (2026-05-18) |
| `#on-device-category-classifier` | — | **Ignore** — IAB page-topic classifier, unrelated to form fields |
| `#on-device-model-litert-lm-backend` | Faster Nano inference | **Evaluate** — flip during TASK-108 latency benchmarking, otherwise ignore |
| `#on-device-model-speculative-decoding` | Faster Nano token generation | **Evaluate** — same: benchmark-only |
| `#optimization-guide-on-device-model` | Force/unblock Gemini Nano download | **Use now** — during spike setup only |
| `#optimization-guide-debug-logs` | See why the model won't download | **Use now** — during spike setup only |
| `#autofill-ai-with-data-schema` / `-available-by-default` | (Chrome feature, not an API) | **Ignore / keep OFF** during guided-session dogfooding |
| `#autofill-ai-server-model` / `-always-trigger-server-model` | — | **Ignore / keep OFF** — sends form context to Google servers (PHI-adjacent machine) |
| `#show-autofill-type-predictions` | Overlay Chrome's field-type guesses while building extension selectors | **Use now** — dev aid for TASK-78 v2 / sandbox provider |
| `#enable-show-autofill-signatures` | Show Chrome's form/field signature hashes | **Evaluate / use now** — dev aid; conceptual parallel to this repo's own signature registry |
| `#autofill-enable-ai-based-amount-extraction` / `-testing` | — | **Ignore** — monetary-amount extraction (checkout totals), irrelevant |
| `#glic-*`, `#glic-actor`, `#glic-actor-script-tools`, `#glic-actor-autofill` | Prior art for TASK-112 supervised automation | **Ignore** (keep off); read the design as competitive context |
| `#glic-disable-actor-safety-checks` | — | **Ignore** — Chrome detects it and silently hides Gemini; never enable |
| `#devtools-webmcp-support`, `#enable-webmcp-testing` | Expose `bin/wwwr match` equivalent as a browser-agent tool | **Evaluate** — does *not* satisfy the interop contract (external CLI can't connect) |
| `#web-machine-learning-neural-network`, `#webnn-coreml`, `#experimental-web-machine-learning-neural-network` | Run a custom ONNX field-classifier on the Apple Neural Engine if Nano is inadequate | **Ignore** — origin-trial, ~2027 production horizon, large lift |
| `#enable-experimental-web-platform-features` | Umbrella to switch on pre-release APIs for a spike | **Evaluate** — simplest way to try embedder/WebMCP, but don't leave on; prefer specific flags |
| `#unsafely-treat-insecure-origin-as-secure` | Secure-context gate for `wwworkremote.localhost` | **Ignore** — `*.localhost` is already a secure context in Chrome; not needed |

---

## Built-in AI (Gemini Nano / on-device)

### The one fact that decides TASK-108: the extension needs no flag

The Prompt API is **stable for Chrome Extensions since Chrome 138** (May 2025) and requires
no flag, no origin-trial token, and no extra manifest permission. It is reachable from the
extension service worker, popup, and side panel; **content scripts cannot call it directly**
and must relay through `background.js`
([developer.chrome.com/docs/ai/prompt-api](https://developer.chrome.com/docs/ai/prompt-api),
[Chromium: Prompt API for extension](https://chromium.googlesource.com/chromium/src/+/main/docs/experiments/prompt-api-for-extension.md),
[prompt-api-origin-trial blog](https://developer.chrome.com/blog/prompt-api-origin-trial)).

That relay already exists in this codebase: `background.js` line ~187–210 is the
`GENERATE_ANSWER` relay (`sidepanel.js`/`content.js` → background → `LLM::AnswerGenerator`),
built for TASK-78. An on-device `CLASSIFY_FIELD` message would follow the identical shape,
except the background handler calls `LanguageModel.create()` locally instead of `fetch()`.

The web Prompt API also **shipped to stable in Chrome 148** (2026-05-05, over formal
objections from Mozilla / WebKit / W3C TAG / Microsoft —
[TechTimes](https://www.techtimes.com/articles/316729/20260516/google-ships-chrome-prompt-api-over-objections-mozilla-apple-w3c-microsoft.htm),
[built-in-apis](https://developer.chrome.com/docs/ai/built-in-apis)). So on Chrome 152 the
Rails app at `wwworkremote.localhost` could call `window.LanguageModel` too — but there is
no use for it there: sense-making happens in the extension, against third-party ATS pages
the Rails app never sees. The `#prompt-api` flag in `chrome://flags` on 152 is now
essentially legacy for the shipped surface; it only gates pre-release behaviour.

Extensions additionally get `LanguageModel.params()` (`defaultTopK`, `maxTopK`,
`defaultTemperature`, `maxTemperature`) which the web does **not** expose — so for
deterministic classification you can already pin `temperature: 0` without
`#prompt-api-sampling-mode` (that flag's `samplingMode: "most-predictable"` enum is the
*web* substitute for the raw knobs extensions already have)
([prompt-api docs](https://developer.chrome.com/docs/ai/prompt-api)).

### Hardware / OS gate (this is the real blocker, not flags)

From [developer.chrome.com/docs/ai/prompt-api](https://developer.chrome.com/docs/ai/prompt-api)
and [get-started](https://developer.chrome.com/docs/ai/get-started):

- **OS**: macOS 13+ (Mike is fine).
- **Storage**: **22 GB free** to trigger the download; the model is deleted if free space
  later drops below 10 GB.
- **GPU**: > 4 GB VRAM, **or** CPU fallback with 16 GB RAM + 4 cores. Apple Silicon
  qualifies via the GPU path.
- **Download**: lazy, on first `LanguageModel.create()`; progress via a `monitor` callback
  (`m.addEventListener('downloadprogress', e => …)`). Inspect state at
  `chrome://on-device-internals`. `LanguageModel.availability()` returns
  `"available" | "downloadable" | "downloading" | "unavailable"`.

Structured output is supported: `responseConstraint` takes a JSON Schema, and
`omitResponseConstraintInput: true` keeps the schema out of the token budget
([prompt-api docs](https://developer.chrome.com/docs/ai/prompt-api)). This is the right
mechanism for field classification — constrain output to
`{kind: enum[...], confidence: number}`.

### Quality ceiling — what Nano is and isn't for

Google's own guidance: **"Gemini Nano is not optimized for factual accuracy, so metadata or
precise knowledge may be unreliable."** The documented sweet-spot use cases are all
*extraction / classification / rewording within the page*: calendar-event extraction,
contact extraction, content filtering/blurring, summarization
([prompt-api-origin-trial blog](https://developer.chrome.com/blog/prompt-api-origin-trial),
[prompt-multimodal-origin-trial blog](https://developer.chrome.com/blog/prompt-multimodal-origin-trial)).

Implication for this repo:

| Task | On-device Nano fit |
|---|---|
| "Is this field work-authorization / demographic / free-text / salary?" (TASK-108) | **Good** — bounded classification, low stakes, exactly the documented sweet spot |
| US-only location filter (classify posting location → in/out of US) | **Plausible** — short-string classification; verify recall on edge cases ("Remote - Americas", "US or Canada") before trusting it to *drop* postings |
| Summarize a long job description | **Good** — Summarizer API, `type: "key-points"` or `"tldr"` |
| Job-fit scoring / match analysis (`LLM::ProfileMatcher`) | **Bad** — needs judgement, calibration, and factual grounding in the resume; keep this on the backend LLM. Do not route `bin/wwwr match` through Nano |
| Drafting a screening-question answer | **Marginal** — Writer/Rewriter could tidy phrasing, but the *content* still needs the backend (it must be true about Mike) |

This matches the TASK-108 comment: on-device sense-making is advisory only, must not weaken
the human approval gate, and the deterministic-vs-approval-gated decision stays with the
existing `GuidedSessionEvent` classification.

### Multimodal (`#prompt-api-multimodal-input`)

Image input is **stable for extensions** (accepts `HTMLImageElement`, `ImageBitmap`,
`Blob`, `VideoFrame`, `Canvas`, etc.); audio input needs a GPU. For the web it was an
origin trial (Chrome 139–144) and is folded into the shipped API on 152
([prompt-multimodal-origin-trial blog](https://developer.chrome.com/blog/prompt-multimodal-origin-trial),
2025-07-21). **Evaluate, don't adopt**: the extension already has structured DOM access to
form fields; feeding a screenshot to Nano is only worth it for canvas-rendered or
iframe-walled forms where DOM extraction fails, which is a later problem.

### Summarizer / Writer / Rewriter / Proofreader

| API | Status (extensions & web) | Source |
|---|---|---|
| Summarizer | **Stable, Chrome 138**. `type`: `key-points`/`tldr`/`teaser`/`headline`; `format`: markdown/plain; `length`: short/medium/long; `expectedContextLanguages` en/ja/es/de/fr | [summarizer-api](https://developer.chrome.com/docs/ai/summarizer-api) |
| Writer | **Developer trial only** | [built-in-apis](https://developer.chrome.com/docs/ai/built-in-apis) |
| Rewriter | **Developer trial only** | [built-in-apis](https://developer.chrome.com/docs/ai/built-in-apis) |
| Proofreader | **Origin trial** | [built-in-apis](https://developer.chrome.com/docs/ai/built-in-apis) |

`#summarizer-api-performance-preference` maps to the `type` argument's speed/capability
tradeoff (`"speed"` = low latency, `"capability"` = fuller output) — already a first-class
option on the stable API, so the flag is redundant.

### Classifier API — dead

The [classifier-api explainer](https://github.com/explainers-by-googlers/classifier-api)
carries a notice: **"No longer pursued due to insufficient signals of interest"**
(2026-05-18). It was never shipped in any Chrome version, used the IAB Content Taxonomy
(page-topic classification, not form-field typing), and its own non-goals excluded
sentiment/translation/summarization. The `#classifier-api` flag, if still present in 152, is
a stub. **Do not build on this.** The [Intent to Prototype](https://groups.google.com/a/chromium.org/g/blink-dev/c/5dQNl-gyjgU)
is the only other trace.

`#on-device-category-classifier` is the separate IAB-taxonomy feature that powers
Chrome-internal categorisation; not a developer API for field classification.

### Semantic Embedder API — not shipped

The [semantic-embedder-api explainer](https://github.com/explainers-by-googlers/semantic-embedder-api)
is an **"early design sketch" that "has not been approved to ship in Chrome"**; available
only in Chrome Canary behind a flag
([Intent to Prototype: Embedding API](https://groups.google.com/a/chromium.org/g/blink-dev/c/EjL1gAy3k3Q/m/31Cnh22MBgAJ)).
API shape: `SemanticEmbedder.availability()` / `.create()` / `embed(text|array)` →
`Float32Array` vectors; possibly backed by EmbeddingGemma or Qwen3-Embedding (unconfirmed);
2048-token cap, no chunking, no vector store.

Relevance to **TASK-32.7**: none, near-term. That task is explicit — reuse the existing
`neighbor`/`pgvector` setup, add no embedding provider, and it runs **server-side in Rails**
where a browser API is unreachable. An on-device embedder would only ever help
*extension-side* work (e.g. dedupe "is this the same posting I saw on LinkedIn?" before
calling home). File that as a someday-idea, not a TASK-32.7 input.

### Inference-engine flags

`#on-device-model-litert-lm-backend` (LiteRT-LM runtime for Nano) and
`#on-device-model-speculative-decoding` (draft-model token acceleration) are internal
performance toggles, not API surface. If TASK-108's latency numbers are borderline, flip
them during benchmarking and measure; otherwise leave default.

`#optimization-guide-on-device-model` and `#optimization-guide-debug-logs` are the
model-provisioning controls — genuinely useful **during spike setup** if
`LanguageModel.availability()` returns `"unavailable"` and you need to see why (region gate,
disk, hardware, enterprise policy). Turn off afterwards.

---

## Autofill AI

This is a **Chrome browser feature, not a web/JS API** — a settings group ("Autofill with
AI" / "Autofill prediction improvements") under Settings → Autofill, where Chrome uses
generative AI to understand a form and fill more fields, adapting to the form's required
format ([blog.google/products/chrome/autofill-improvements](https://blog.google/products/chrome/autofill-improvements/),
[Android Police](https://www.androidpolice.com/google-chrome-new-autofill-ai-wip/),
[Chrome Enterprise: AutofillPredictionSettings](https://chromeenterprise.google/policies/autofill-prediction-settings/)).
`-with-data-schema` says on-device; **`-server-model` / `-always-trigger-server-model` send
form context to Google** for the prediction.

**For TASK-112 guided-session dogfooding: keep all four OFF.** The guided session records
"what field did Mike decide, and did he approve it." If Chrome autofills a field
underneath, the `GuidedSessionEvent` timeline can't tell a Mike-typed value from a
Chrome-generated one — provenance is the whole point of that timeline (same reason TASK-78
tags captured answers `submitted` vs `canned`/`ai`). The server-model variants also violate
the PHI-adjacent no-data-egress posture. **Add "Autofill with AI disabled" to the
guided-session dogfood checklist** alongside the existing "reload the extension from
chrome://extensions" note.

### Dev aids (these are useful)

- **`#show-autofill-type-predictions`** — annotates every form field on a page with the
  field type Chrome inferred. Directly useful when writing/verifying the extension's
  Greenhouse/Workday/Lever selectors (TASK-78 v2, the sandbox provider's fake-ATS DOM) —
  it's a free second opinion on what each field "is"
  ([Chrome DevTools autofill blog](https://developer.chrome.com/blog/devtools-autofill)).
  **Use now.**
- **`#enable-show-autofill-signatures`** — surfaces Chrome's form-signature and
  field-signature hashes (Chrome's own stable identifiers for a form across page loads).
  Conceptually the same move as this repo's `docs/architecture/signature-registry.md`.
  Worth a look while designing scenario signatures; low cost to leave on during dev.
- **`#autofill-enable-ai-based-amount-extraction` / `-testing`** — pulls monetary amounts
  (order totals, prices) out of pages. No job-application use. **Ignore.**

---

## Agentic browsing (glic / Gemini-in-Chrome)

"Glic" is Chrome's internal name for Gemini-in-Chrome; its **actor** engine lets Gemini
operate the browser — open tabs, click, fill forms — gated behind explicit user consent
([Chrome Story: browser actuator / glic flags](https://chromestory.com/2026/08/chromium-browser-actuator-glic-flags/),
[Chrome Story: Gemini agent form-filling fix](https://chromestory.com/2026/06/chromium-gemini-agent-form-filling-fix/)).
`#glic-actor-autofill` is the actor's form-filling path; `#glic-actor-script-tools` its
scripted-tool set. **`#glic-disable-actor-safety-checks` is a trap** — production Chrome
detects it and silently hides the Gemini entry point.

**Verdict: keep off, read as prior art.** TASK-112's pump-track (supervised lap, human veto
at irreversible transitions, deterministic replay of known-safe steps) is solving the same
problem Google's actor solves, with a stricter safety model. One reusable technique from
the actor's design: *click/focus a field before filling it* so Chrome re-parses the DOM and
reveals click-gated fields — relevant to the extension's field capture on lazy ATS forms.
Enabling glic in Mike's dogfooding profile risks the Gemini overlay and actor competing
with the extension for the same page.

---

## WebMCP

Status: **WICG incubation**, first published 2025-08-13, spec at
`webmachinelearning.github.io/webmcp/`; behind `#devtools-webmcp-support` /
`#enable-webmcp-testing` (or the experimental-web-platform-features umbrella), not an origin
trial ([github.com/webmachinelearning/webmcp](https://github.com/webmachinelearning/webmcp)).

What it does: a page calls `document.modelContext.registerTool({name, description,
inputSchema, execute})` (or declares tools from `<form>` elements) to expose functionality
to an **in-browser AI agent**. Same-origin by default; cross-origin iframes need
`allow="tools"`. **The browser mediates every call — external processes do not connect
directly.**

Relevance to `docs/agents/interop.md`: **it does not fit the interop contract.** That
contract exists so *other on-box tools* (the just3ws CLI, `rails runner` from another repo)
get job-fit scoring through one entry point, `bin/wwwr match`. Those are separate OS
processes. WebMCP can only be invoked by an agent running inside the Chrome tab that has
`wwworkremote.localhost` open — it cannot be a transport for a CLI. It would only become
interesting if Mike later wants to drive wwworkremote *from* an in-Chrome agent (e.g. "hey
Gemini, score this posting"), which is a different feature from the interop contract.
**Evaluate, keep separate from interop.**

---

## WebNN (lower-level ML fallback)

Status: **origin trial in Chrome 146–149** (promoted Feb 2026), **not stable**, best
production estimate ~2027
([Phoronix: Chrome 146 Beta](https://www.phoronix.com/news/Chrome-146-Beta),
[Intent to Experiment: WebNN](https://groups.google.com/a/chromium.org/g/blink-dev/c/5CWKSChYo98),
[webmachinelearning.github.io/webnn-status](https://webmachinelearning.github.io/webnn-status/)).
`#webnn-coreml` selects the Core ML backend on macOS (routes to the Apple Neural Engine),
implemented but immature. `#experimental-web-machine-learning-neural-network` unlocks
newer/experimental ops.

This would be the path if TASK-108 concludes Gemini Nano *can't* classify fields well
enough and a purpose-trained model is justified: train a small classifier, export ONNX,
run it via WebNN on the NPU. That's a multi-week effort (model, training data, ONNX op
coverage gaps, fallback handling) and premature — **ignore until the Nano evaluation
actually fails.** WebNN's real advantage over WebGPU is NPU access, which matters on
M-series Macs, so the fallback is technically sound, just not now.

---

## Umbrella / enabling flags

- **`#enable-experimental-web-platform-features`** — turns on a broad set of pre-release
  APIs at once, including the embedder/WebMCP surfaces. Convenient for a one-sitting spike,
  but it's a blunt instrument that changes page behaviour widely. Prefer the specific flag;
  if you use the umbrella, turn it back off.
- **`#unsafely-treat-insecure-origin-as-secure`** — **not needed.** Chrome treats
  `http://*.localhost` (and `http://localhost:*`) as a
  [potentially-trustworthy origin](https://developer.chrome.com/docs/ai/get-started) /
  secure context, so `http://wwworkremote.localhost` already satisfies any secure-context
  gate. The extension's service worker and content scripts are secure contexts too. (The
  extension already defaults to `http://localhost:31000` per TASK-78 notes and works.)

---

## Recommended next steps for TASK-108

1. **Flip nothing first.** In the extension service worker, log
   `await LanguageModel.availability()`. If it returns `"available"` or `"downloadable"`,
   the entire "which flags" question is moot for the extension — proceed with no flags.
2. **If it returns `"unavailable"`**: enable `#optimization-guide-on-device-model` and
   `#optimization-guide-debug-logs`, check `chrome://on-device-internals`, confirm 22 GB
   free. These are the only flags TASK-108 should ever need, and only for provisioning.
3. **Prototype the relay** (AC #2): add a `CLASSIFY_FIELD` message handler in
   `background.js` mirroring the existing `GENERATE_ANSWER` relay (line ~187). Content
   script sends `{label, type, surroundingText}`; background calls `LanguageModel.create()`
   with a system prompt and `responseConstraint` = `{type, enum: [identity, contact,
   eligibility, logistics, experience, motivation, demographic, free_text, other]}` — the
   same taxonomy as `ApplicationFieldQuestionClassifier::TYPES`.
4. **Benchmark against the sandbox provider** (TASK-104) once it exists: run the on-device
   classifier over the fake-Greenhouse fields, compare its labels to
   `ApplicationFieldQuestionClassifier`'s regex output and to a backend `LLM::Orchestrator`
   call. Measure latency and agreement. If latency is borderline, retest with
   `#on-device-model-speculative-decoding` on.
5. **Test the US-only location classifier separately** — feed it real posting location
   strings (including "Remote — Americas", "US or Canada", "EMEA") and check it never
   *drops* a US-eligible posting. Recall matters more than precision for a hard-filter.
6. **Keep the recommendation advisory** (AC #3, per the task comment): on-device output
   annotates a `GuidedSessionEvent`, it never decides an approval gate. The output of
   TASK-108 is a decision (adopt / defer / reject) plus this doc, not necessarily shipped
   code.
7. **Do not** route `bin/wwwr match` or `LLM::ProfileMatcher` through Nano — factual-accuracy
   ceiling. On-device is for cheap field classification and summarization only.

### Dogfooding hygiene (TASK-112)

Add to the guided-session dogfood checklist: **disable "Autofill with AI"** (Settings →
Autofill) and **do not enable any `#glic-*` flag** in the profile used for recording — both
let Chrome mutate or drive fields the session is trying to attribute to Mike.
