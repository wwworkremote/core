# WWWorkRemote backlog

## Job application lifecycle

WWWorkRemote treats an application as a continuation of a tracked job lead:

`discover → capture → enrich → evaluate → prepare → fill → submit → follow up → close`

Each stage retains the identifiers and evidence needed to reconstruct what happened:

- `lead_id` / `job_posting_id`: the tracked job and its canonical posting URL.
- `wwr_id`: the job-posting correlation passed through ATS URLs.
- `trace_id`: the end-to-end interaction trace for extension, page, API, and status events.
- `application_id`: the application record, including ATS/provider and every observed application URL.
- `persona_id`: the resume persona and answer profile used for the application.
- field mappings and answer observations: the semantic question-to-answer relationship, source, confidence, override, and history.
- submission evidence: captured fields, completion-page evidence, timestamp, provider response, and user confirmation.

### Planned work

1. **Lifecycle model and evidence**
   - Define application states and valid transitions.
   - Make submission idempotent and distinguish “already submitted” from transport/API failure.
   - Persist completion evidence and the final ATS URL.

2. **Extension reliability**
   - Keep dynamic-field discovery active as SPA/Workday steps mount.
   - Add user-selectable submit/completion triggers and a manual “Done / capture submission” action.
   - Keep the side panel opening user-gesture-safe, with retry guidance and keyboard-toggle help.
   - Display extension version/build, `wwr_id`, and `trace_id` in diagnostics and screenshots.

3. **Application cockpit**
   - Select a canonical just3ws resume persona.
   - Load stable personal fields separately from persona-specific history and answers.
   - Support click-to-map, fill, copy, edit, save, and per-application overrides.
   - Preserve mappings across provider layouts and record corrections as training context.

4. **Question intelligence**
   - Classify questions by semantic type and ATS/provider.
   - Aggregate recurring questions and answer patterns across applications.
   - Maintain canonical answers with persona overrides, confidence, provenance, and historical revisions.
   - Use local/context-grounded analysis first; route only explicitly permitted work to an external model.

5. **Provider coverage and funnel reporting**
   - Track ATS/provider families and their posting, application, completion, and status URL patterns.
   - Add funnel reporting: leads, applications started, applications submitted, responses, interviews, offers, and closures.
   - Record provider-specific navigation lessons, including nested posting lists and reading-pane routes.

6. **Observability and coordination**
   - Capture extension console errors, API failures, page readiness, field observations, and submission attempts.
   - Correlate all telemetry with `trace_id` and `wwr_id` without sending sensitive field values by default.
   - Publish material lifecycle incidents and integration decisions to the `job-leads` Communication Bus channel.
   - Keep handoffs current in `~/.config/adots/handoffs/`.

## Current implementation notes

- The Chrome extension is currently v1.24.7 (local unpacked build).
- Workday completion detection and manual application-status capture are implemented.
- The already-applied HTTP 200 response is handled idempotently by the extension.
- The extension and Rails bridge have dynamic application-field support, persona/profile support, mappings, observations, telemetry, trace IDs, and recent-enrichment links in progress.
- Do not treat third-party analytics certificate errors as WWWorkRemote submission failures; separate provider-page noise from extension/API errors.

## Execution order

Validate the current local application-status path first, then harden submit/completion capture, then finish persistent field mapping and question history, and finally expand provider-specific funnel reporting and AI-assisted answer generation.
