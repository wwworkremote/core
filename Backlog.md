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
- The `.home.arpa` + local AdGuard DNS rewrite approach was abandoned: macOS/iOS's resolver
  (`getaddrinfo`, used by curl, Safari, and every real app) silently refuses to resolve `.arpa`
  names at all, even though `dig` against the AdGuard server succeeded — nginx, the cert, and
  Rails all worked once DNS was bypassed with `--resolve`, confirming it was purely a resolver
  issue with the reserved TLD, not fixable on this end.
- Replaced with a real public DNS A record: `lan.wwworkremote.com → 10.36.1.149`, added directly
  in DNSimple (same zone as `node01`–`node05.wwworkremote.com`). This resolves normally
  everywhere via the standard resolver path (no mDNS/`.arpa` special-casing) but only connects
  from the trusted LAN, since the address itself isn't routable from outside it.
- The supported service controller is `bin/wwworkremote-ctl`, with launchd-backed `start`, `stop`, `restart`, and `status` commands.
- Rails development host authorization now allows `lan.wwworkremote.com` and loopback addresses.
- `bin/wwworkremote-ctl start/restart web` now waits up to 30 seconds for Puma to answer HTTP requests.
- Shared navigation, admin dashboard/jobs, job-posting index, and job-posting detail views now have a mobile-first responsive pass.
- Source-owned Nginx vhost now serves `lan.wwworkremote.com`; the live Nginx config and local
  certificate still require operator deployment (`ops/nginx/deploy.sh`, which now verifies with
  real cert validation instead of `curl -k`, so a SAN gap fails loudly).
- No network exposure, firewall rule, or authentication change beyond the above is authorized by this task alone.

### Completed prerequisites

- [x] Reserve a stable DHCP lease for the host.
- [x] Add a real public DNS A record (`lan.wwworkremote.com`) instead of a reserved-TLD LAN rewrite.
- [x] Allow `lan.wwworkremote.com` through Rails Host Authorization.
- [x] Make web start/restart wait for HTTP readiness.
- [x] Add the first mobile-friendly admin and job-posting views.
- [x] Verify DNS resolution for `lan.wwworkremote.com` via the real resolver path (curl/getaddrinfo), not just `dig`.
- [ ] Verify HTTP reachability from a second LAN device (phone).
- [ ] Deploy the updated Nginx vhost and regenerate the local certificate with the `lan.wwworkremote.com` SAN.
- [ ] Remove the now-unused `wwworkremote.home.arpa`/`wwwr.home.arpa` AdGuard rewrites (operator-owned, outside this repo).

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

## Backlog task: Review-queue UX ("Skip Tax" audit)

Both review-queue screens -- Rails job posting triage and the extension's application field
review -- implement the same loop (show one item, decide, advance) with mismatched touch-target
sizing and no shared interaction language between them. Full audit, evidence, and severity
ranking: see the "Skip Tax" artifact from this session.

### Shipped

- [x] Real 44px `<button>` for triage Skip, moved to primary visual weight (was `btn-ghost btn-sm`).
- [x] Triage decision bar (Skip + Favorite/Not interested/Expired) pinned to the viewport bottom
      via a `fixed` bar, decoupled from the form with an HTML `form="triage-form"` attribute so it
      stays reachable regardless of scroll position.
- [x] Focus moves to the posting heading on every triage page load (`triage_controller.js#connect`),
      so a screen reader announces the new item across the full-page reload.
- [x] Real `<label for>` on both free-text fields (triage note, sidepanel field answer).
- [x] Sidepanel action buttons (`Fill`/`Map`/`Skip`/status) resized to a 36px minimum height, with
      per-row `aria-label`s so repeated "Fill"/"Map" buttons are distinguishable to assistive tech.
- [x] Added a per-field Skip to the sidepanel's application field review -- the one primitive triage
      had that the extension didn't. Dismisses the row for the current render only, not persisted.
- [x] Heading-level skip fixed (h1 -> h2, was skipping straight to h3/h4), a global
      `prefers-reduced-motion` guard added for animate-spin/pulse/bounce/ping (8 view files used
      them unguarded), and a suppressed focus ring on the command palette search input replaced
      with a real `focus:border-primary` indicator.
- [x] Replaced the Dracula Pro theme with a verified-contrast graphite/blue palette -- every color
      checked against all three base surfaces (the old palette was only ever checked against
      base-100, and silently failed 4.5:1 against base-300). Caught and fixed a real regression in
      the same pass: the Agent Wire tab hardcoded literal `dracula-*` classes that would have lost
      their styling.
- [x] Site footer hidden during triage -- the fixed decision bar was overlapping it on short
      viewports, found by actually looking at the rendered page rather than trusting the CSS.
- [x] Live-viewport confirmation that the triage decision trio doesn't truncate at 375px width --
      confirmed on a real phone (Firefox/Android): "Not interested" wraps to two lines cleanly,
      doesn't truncate, no footer overlap, Skip reachable without scrolling.

### Not done

- [ ] One documented shared interaction pattern (target sizing, labeling, "decide and advance"
      vocabulary) applied consistently to both surfaces, rather than fixed independently as above.
- [ ] Swipe gesture on the triage view as the phone-native equivalent of the F/N/E/S/B keyboard
      shortcuts (shortcuts still have no mobile equivalent).
- [ ] Progress indicator ("N left in today's queue") on the triage bar -- was in the revamp mockup,
      not in the shipped fix list.
