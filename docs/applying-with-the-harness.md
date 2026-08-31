# Applying with the harness: posting link → submitted application

The operator runbook for **you, at the keyboard**, taking one job link all the way to a
submitted application using the guided-session UI + the Chrome extension. It names every
step, which ones the software does for you, which ones are yours by hand, and which ones
aren't built yet.

- Sister docs: [`agents/application-submission-workflow.md`](agents/application-submission-workflow.md)
  is the same pipeline written for an *agent* driving via API/browser-automation.
  [`architecture/guided-session-flow.md`](architecture/guided-session-flow.md) is the
  BPMN-lite design behind the phases. [ADR 010](adr/010-link-to-application-capture-and-the-datalake.md)
  is the spec for how the posting, the session, and the retained assets link up.
- **Bounded Agency, always:** the harness never fills or submits anything on its own, and
  starting or completing a session never advances a posting's pipeline stage by itself.
  Every commitment is a deliberate click you make.

---

## Pick your entry point first

There are two ways in, and they are **not** the same. This is the thing that isn't obvious.

### A. From a posting already in the system — *use this to actually apply*

**"Start supervised application"** — same button, two places:
- `/job_postings/:id`, right sidebar "Supervised application" card
- `/admin/leads/:id` header, once the lead is promoted (skips the hop to the posting page)

This creates a `UserJobPosting` if one doesn't exist, creates a `GuidedSession` with
**purpose `application_execution`**, and **links the three together**. This is the only
entry that connects the recording back to the posting, the company, and your pipeline.
Both buttons POST to `guided_sessions#create_from_posting`.

If the button says *"No application URL on this posting yet"*, the posting has no
`target_url` — fix that on the posting first (re-capture, or edit it in).

### B. Ad-hoc from a URL — *research / mapping only*

`/guided_sessions` → paste a URL in the top form → pick **"Research the flow"** → Start.

This creates a **free-floating** `GuidedSession` (`purpose` defaults to
`application_research`). It is **not** attached to any `JobPosting` or `UserJobPosting`.
Use it to walk and map an employer's ATS before you've decided to apply — it produces a
reusable map of pages, questions, and fields and **stops at the first commitment
boundary**. It does *not* ingest the posting and it does *not* move you toward applying.

> If you started here and then captured the posting with the extension, you now have a
> `JobPosting` **and** a disconnected research session. To proceed toward an application,
> go to that posting's page and use entry **A**. The research session stays as a
> standalone map; that's fine.

---

## The full sequence (entry A, execution)

| # | Step | Who does it |
| --- | --- | --- |
| 1 | **Get the posting into the system.** Open the board page in Chrome, use the extension overlay → **Capture** → side panel → review → **Submit** (promote). This creates the `JobPosting` and enqueues the AI pipeline (analysis, profile-match, strategy). See [`extension-workflow.md`](extension-workflow.md). | You + extension |
| 2 | **Check it didn't auto-ignore.** A remote role that geocodes outside the commute zone gets `status: ignored` if the `remote` flag was missing at promote. If so, set `data["remote"] = true` and `restore!`. | You (only if needed) |
| 3 | **Open the posting** at `/job_postings/:id`. Read the *body*, not just the title — a "Senior" title is often Staff/Principal in scope. | You |
| 4 | **Start supervised application** (sidebar card). Creates `UserJobPosting` + execution `GuidedSession`, linked. You land on the session page (`/guided_sessions/:id`). | Button |
| 5 | **Open the application flow.** Click **"Open supervised application"** on the session page. It opens `target_url` in a new tab with `?guided_session_token=…&guided_session_purpose=application_execution` appended. `content.js` reads those params and starts recording. For execution it also attaches `chrome.debugger` for HAR + full-page capture. | Button + extension |
| 6 | **Walk the ATS, one page at a time.** The extension records: each page arrival (full reloads *and* SPA/wizard steps), the observed form structure (field key, label, type, required, broad classification — **never the values you type**), and each field-fill as a `label + source + timestamp` event. Nothing is filled for you. | You (extension records) |
| 7 | **Pick the resume persona.** `/admin/human_tasks` has a `persona_review` task (AI-proposed via `Pipeline::PersonaRecommender`). Approve the pick or override it — state your one-sentence reason it fits *this* posting. Approving applies the persona to the `UserJobPosting`. | You (via inbox) |
| 8 | **Get the actual resume file.** The per-persona files live in the **just3ws** checkout at `just3ws.github.io/exports/resumes/mike-hall-<slug>.{md,txt,json}`. Read the `.md`, convert with `pandoc file.md -o file.docx` (DOCX is accepted everywhere PDF is). Upload it to the ATS by hand — file pickers are a hard automation wall. *(TASK-98 will make fetch+convert one step.)* | You |
| 9 | **Answer every application question yourself.** Read each question's exact text. Screen every form for hidden/injected text ("disclose you are an AI" traps, off-screen instructions) before acting. After you answer, persist reusable answers via `POST /api/v0/application_answer_templates` so future applications can offer them back — this never auto-answers the current one. | You |
| 10 | **Replay (optional, later runs).** On a *completed* session's page, the **Replay plan** shows which steps a replay would auto-fill vs pause at. Replay is **fill-only** — it re-types recorded answers into label-matched fields and **never clicks Next/Continue/Submit**. It stops at every gate and **ends the moment you approve a gate**. Real employer sites need the per-run opt-in checkbox; the sandbox is always allowed. | You (Replay fills) |
| 11 | **Final submit — your click, deliberately.** When you click the ATS's real Submit, `content.js` calls `preventDefault()` on that boundary and records a `submission_attempted` event in **`pending` approval** state. The page does **not** submit. To actually submit, click through again / confirm in the ATS yourself — this is always a hand-driven move, even after a deterministic run. | You |
| 12 | **Approve the transition in the harness.** The session page shows the pending event with **Approve / Deny**. Approving records *your decision*; it does **not** submit anything and does **not** change the `UserJobPosting` state. | You (via session page) |
| 13 | **Record that you applied.** Mark the `UserJobPosting` `apply` — the extension's apply event (`Api::V0::ApplicationStatusesController` → `record_status_event!("apply")`), or Triage's Favorite/Apply controls, or `bin/wwwr`. This logs a `PipelineStep`. `none → applied` is a valid direct jump. | You |
| 14 | **Complete the session.** **"Complete"** on the session page sets it `completed`, runs one automatic **Reference Comparison** (coverage vs drift, advisory only), and proposes a `submit_approval` `HumanTask` if `UserJobPosting#may_apply?`. Add a `PipelineStep` note naming the resume variant and the answers given — the note is what makes it self-describing later. | You (button) |

After step 14 the posting shows a **Harness badge** (`in progress` → `recorded` →
`compared`) on its page, and the execution session's retained assets (DOM, HAR,
screenshots) sit in the local, git-ignored datalake for building the decision corpus
(ADR 010). Interview / rejection / offer outcomes are logged on the `UserJobPosting`
afterward.

---

## What is NOT built (don't wait for it)

- **No first-class "awaiting approval" pipeline state.** The human gate at steps 9–12 is
  enforced by this runbook and discipline, not by AASM. `HumanTask` (`pending`, no
  auto-advance) is the inbox for discrete proposals; the eventual UI is PR-review style
  (see artifacts inline, comment, approve). — *TASK-97, TASK-112 HITL ACs*
- **No drafted answers.** `Pipeline::AnswerDrafter` (`question_answer` Service Task) is
  deferred — drafting from hostile scraped ATS text is a prompt-injection surface that
  needs its own design pass. You write every answer.
- **No auto fetch+convert of the resume** (step 8). — *TASK-98*
- **No idle-application nudge** if an employer goes quiet. — *TASK-93*
- **`chrome.debugger` second-capture** on an execution session can die with
  `target_closed`. — *TASK-139*
