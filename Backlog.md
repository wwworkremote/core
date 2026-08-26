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

## Backlog task: LAN/mobile access

Enable an intentional, secure way to use WWWorkRemote from another device on the same LAN, especially a phone.

### Current state

- Puma is configured for port `31000` and currently reports a wildcard listener (`*:31000`).
- DHCP now reserves `10.36.1.149` for the WWWorkRemote Mac, making the LAN address stable.
- AdGuard DNS rewrites now map `wwworkremote.home.arpa` and `wwwr.home.arpa` to `10.36.1.149` (`wwr.home.arpa` is also allowed as an alias).
- The supported service controller is `bin/wwworkremote-ctl`, with launchd-backed `start`, `stop`, `restart`, and `status` commands.
- Rails development host authorization now allows the two approved LAN names and loopback addresses.
- `bin/wwworkremote-ctl start/restart web` now waits up to 30 seconds for Puma to answer HTTP requests.
- Shared navigation, admin dashboard/jobs, job-posting index, and job-posting detail views now have a mobile-first responsive pass.
- Source-owned Nginx vhost/deploy verification now includes both approved `.home.arpa` names; the live Nginx config and local certificate still require operator deployment.
- No network exposure, firewall rule, public DNS, or authentication change is authorized by this task alone.

### Completed prerequisites

- [x] Reserve a stable DHCP lease for the host.
- [x] Add the `wwworkremote.home.arpa` AdGuard rewrite.
- [x] Add the `wwr.home.arpa` AdGuard rewrite.
- [x] Allow the canonical `wwwr.home.arpa` LAN hostname through Rails Host Authorization.
- [x] Allow the approved LAN hostnames through Rails Host Authorization.
- [x] Make web start/restart wait for HTTP readiness.
- [x] Add the first mobile-friendly admin and job-posting views.
- [ ] Verify resolution and HTTP reachability from a second LAN device.
- [ ] Deploy the updated Nginx vhost and regenerate the local certificate with both `.home.arpa` SANs.

### Required changes

- Add a documented LAN-access mode with an explicit bind/host configuration and a discoverable, stable local URL.
- Add a health/readiness check that waits for Puma to accept connections after clean restart; avoid reporting “running” before the HTTP listener is ready.
- Verify launchd restarts preserve the bind configuration and do not leave stale web or Solid Queue processes.
- Define the access boundary: LAN-only by default, no router port forwarding, and no unauthenticated exposure beyond the trusted network.
- Decide how phone access authenticates and how session cookies/CSRF protections behave on a second device.
- Provide a mobile-responsive route/layout for the dashboard and application funnel; keep extension-only controls unavailable or clearly separated on mobile.
- Add an operator runbook covering IP/hostname discovery, firewall approval, health checks, clean restart, and rollback.
- Add automated checks for bind configuration, readiness, authentication, and representative mobile viewport rendering.

### Acceptance criteria

- From a second device on the same trusted LAN, the operator can reach the documented URL and authenticate without exposing the service to the public Internet.
- `bin/wwworkremote-ctl restart all` returns only after web readiness is confirmed, or clearly reports a bounded startup failure.
- `/admin/jobs` and the mobile funnel view load successfully over the LAN after restart.
- A failed or revoked LAN-access setup leaves localhost access working and has a documented rollback.
- Tests cover the readiness contract, access boundary, and mobile layout smoke path.

### Mike-owned steps

- [ ] Confirm both DNS names resolve to `10.36.1.149` from the phone.
- [ ] Confirm the phone and Mac are on the trusted LAN/VLAN.
- [ ] Approve or configure the macOS firewall rule allowing TCP `31000` from the trusted LAN only.
- [ ] Choose and verify the authentication method from the phone; do not expose an unauthenticated dashboard.
- [ ] Decide whether to use HTTPS with a locally trusted certificate for phone access.
- [ ] Test `/admin/jobs` and the mobile funnel on the phone and report the exact URL/status if either fails.

### Still not enabled

- LAN reachability from the phone has not been verified from a second device.
- macOS firewall policy, HTTPS/local certificate trust, and production-grade LAN authentication remain unconfigured.
- Mobile-specific application-funnel actions, extension controls, and offline/PWA behavior are not enabled.
- Nginx has been reloaded successfully, but the repo does not yet own a stable LAN virtual-host configuration or readiness-aware Nginx health check.
- Responsive rendering has been covered by markup/request tests only; a real-device viewport pass is still required.
