---
id: TASK-77
title: 'Admin::Documents "lists documents newest first" spec fails deterministically'
status: Done
assignee: []
created_date: '2026-08-19 21:25'
updated_date: '2026-08-19 21:37'
labels: []
dependencies: []
references:
  - spec/requests/admin/documents_spec.rb
  - app/controllers/admin/documents_controller.rb
priority: low
type: bug
ordinal: 90000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
ROOT CAUSE FOUND (was initially misdiagnosed as unrelated pre-existing flakiness -- it is not). `spec/requests/admin/documents_spec.rb:7` asserts document ordering via `response.body.index(signature_string)` on the literal signatures `"older"`/`"newer"`. TASK-76's command palette added `placeholder="Jump to a page..."` to the layout (`app/views/layouts/application.html.erb`) -- the HTML attribute name `placeholder=` itself contains the substring `"older"`, and the palette's dialog renders early in `<body>`, before the documents table. `response.body.index("older")` was matching that attribute name, not the intended table row, making the assertion fail regardless of actual (correct) row order.

Confirmed via a scratch debug spec using non-colliding signatures (`"olderdbg"`/`"newerdbg"`): ordering is and always was correct (`JobBoards::Document.order(created_at: :desc)` works fine); only the test's fragile substring-matching broke.

Fixed in the same session: signatures changed to longer, collision-resistant values in the spec itself, since the real defect is the test's fragile assertion style (any future page copy containing "older"/"newer" as a substring -- e.g. "folder", "reorder" -- would reintroduce this), not the production code.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Root cause: not a pre-existing bug, a real (if narrow) regression -- TASK-76's command palette placeholder attribute contains "older" as a substring, colliding with this spec's fragile `response.body.index("older")`/`"newer"` substring-matching assertion. Fixed by using longer, collision-resistant signature values in the spec. Production ordering code was never wrong.
<!-- SECTION:FINAL_SUMMARY:END -->
