---
id: TASK-37.2
title: >-
  Regression-check picker/teach flow and LinkedIn/Indeed after shared-helper
  refactor
status: To Do
assignee: []
created_date: '2026-08-13 17:40'
labels: []
milestone: m-1
dependencies: []
parent_task_id: TASK-37
priority: medium
type: chore
ordinal: 1100
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
This session introduced or changed several extraction helpers shared across providers: `pickAttr`, `pickLabeledValue`, `companyFromTitleSuffix`, `companyFromWorkdayHostname`, `companyFromSmartRecruitersPath`, and `jsonLdMatchesCurrentPage` (a new guard in `Extractor.jsonLd()` that rejects a JSON-LD candidate whose title doesn't match the current page -- added after finding RemoteOK embeds an entire unrelated job feed's JSON-LD on every posting page). Neither the "teach the extractor" element-picker flow (`app/controllers/api/extraction_rules_controller.rb`, `JobBoards::SelectorLearnerAgent`, the picker UI in `content.js`/`sidepanel.js`) nor the LinkedIn/Indeed extractors (fixed in an earlier part of this session, before the shared-helper changes) have been re-verified against the current build.

Read `docs/extension-workflow.md`'s "Teach the Extractor" sequence diagram before starting.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The teach flow is exercised live on at least one provider: clicking the picker button, selecting an element on a real page, and confirming both an ExtractionRule (current value) and an ExtractionRuleObservation (history entry) are created with the expected selector
- [ ] #2 A learned rule is confirmed to actually apply on the next extraction of that provider (the taught field shows the taught value, not the original guess)
- [ ] #3 LinkedIn is re-verified live against a real posting: title/company/location/salary/employment_type/remote extracted correctly, including via the insight-pill classifier
- [ ] #4 Indeed is re-verified live against a real posting
- [ ] #5 Any regression found from the shared-helper changes is fixed and covered by a spec or documented live-verification note
<!-- AC:END -->
