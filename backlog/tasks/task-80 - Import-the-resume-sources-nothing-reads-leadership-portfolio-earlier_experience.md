---
id: TASK-80
title: >-
  Import the resume sources nothing reads (leadership, portfolio,
  earlier_experience)
status: To Do
assignee: []
created_date: '2026-08-22 15:22'
labels: []
dependencies: []
priority: medium
type: feature
ordinal: 93000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`Resume::YamlImporter` reads `profile.yml`, `skills.yml`, and `positions/*.yml`. Four sources in the just3ws repo are read by nothing, so their evidence cannot reach `LLM::AnswerGenerator`:

- `leadership.yml` — 3 of its 6 items are orphaned (not covered by any position file): the enterprise OpenTelemetry ownership handoff, founding Software Craftsmanship McHenry County (823 members), and founding UGtastic/WHOIS.
- `portfolio.yml` — 5 projects; UGtastic, Chicago Code Camp, and UGl.st have no position file at all.
- `earlier_experience.yml` — the 1999–2011 career foundations block.
- top-level `case_studies.yml` — quantified outcomes. Partially mitigated: per-position `case_study` blocks are now imported, but the top-level file still holds numbers that no position file carries.

## Preferred approach
Don't add four more YAML readers. just3ws already serves `site.data.resume` in full over HTTP as `resume.json` (see `docs/just3ws-interop-protocol.md`), and that payload contains `leadership`, `earlier_experience`, and `timeline` alongside what's already imported. Switching the importer's source from the peer's working tree to that endpoint closes this task and the filesystem-coupling defect in one change, and makes the two systems peers across a boundary instead of one reaching into the other's checkout.

Needs: HTTP fetch with the site possibly down, and a decision on whether the filesystem path stays as a fallback. `JUST3WS_RESUME_PATH` already exists as the interim escape hatch.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 leadership.yml content is retrievable by LLM::AnswerGenerator
- [ ] #2 portfolio-only projects (UGtastic, Chicago Code Camp, UGl.st) exist as WorkExperience rows or are explicitly declined
- [ ] #3 earlier_experience 1999-2011 block reaches the corpus
- [ ] #4 The importer no longer depends on a filesystem path into the just3ws checkout
- [ ] #5 Importer degrades safely when the just3ws site is not running
<!-- AC:END -->
