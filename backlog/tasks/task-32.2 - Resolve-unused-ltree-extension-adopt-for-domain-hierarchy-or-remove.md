---
id: TASK-32.2
title: 'Resolve unused ltree extension: adopt for domain hierarchy or remove'
status: Done
assignee:
  - claude
created_date: '2026-08-08 15:49'
updated_date: '2026-08-08 16:21'
labels: []
milestone: m-0
dependencies: []
parent_task_id: TASK-32
priority: medium
type: chore
ordinal: 33000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Goal: the `ltree` Postgres extension (`enable_extension "ltree"` in db/schema.rb, enabled by an early extensions migration) is enabled but has zero references anywhere in app/ or packages/ -- confirmed by repo-wide grep during the 2026-08-08 capability audit. An enabled-but-unreferenced extension is schema debt: it's unclear to future readers whether it's load-bearing, and it costs nothing to carry until someone assumes it's safe to touch and gets surprised.

The one real hierarchical structure in the schema today is `domains.root_domain_id` (a self-referential parent/child FK on the Domain model, just indexed in migration 20260804232042_add_performance_and_integrity_indexes). It currently works as a plain adjacency list. `ltree` would let subtree/ancestor queries (e.g. "all domains under this root, including it, in one query") be expressed natively and cheaply via a path column instead of recursive CTEs -- useful if the company/domain-blocking hierarchy (see ea75aad "auto-block big-tech companies from the ingestion pipeline") ever needs multi-level subtree queries.

This task is a decision-and-execute task, not a research-only spike: investigate whether Domain's hierarchy has (or is about to have) query patterns that justify ltree (subtree lookups, ancestor checks beyond one level), and either:
(a) adopt ltree for Domain by adding a path column derived from root_domain_id and using it for at least one real query path, or
(b) remove the ltree extension from schema.rb/a new migration if no current or near-term caller justifies keeping it.

Whichever direction, the outcome must leave the codebase in a state where "is ltree used" has an unambiguous, correct answer.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A documented decision (recorded in this task) on whether ltree is adopted or removed, with the reasoning tied to actual Domain hierarchy query needs found during investigation
- [ ] #2 If adopted: at least one real query path in the codebase uses ltree path operators (not just a column added and left unused), and existing domain-hierarchy behavior (company/domain blocking) is unchanged per existing specs
- [x] #3 If removed: the extension is dropped via a proper reversible migration, schema.rb no longer lists it, and nothing in the codebase references it
- [x] #4 Full RSpec suite passes after the change
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Decision: REMOVE the ltree extension. Investigation before deciding:
- Confirmed via repo-wide grep that `ltree` has zero references anywhere in app/ or packages/ (matches the audit finding).
- Went further than the audit did: grepped for `root_domain_id`/`root_domain` outside the schema annotation comment -- also zero hits. `Domain` (app/models/domain.rb) doesn't even declare a `belongs_to :root_domain` or `has_many` self-association for it; the column is pure unused schema, not "used informally without ltree."
- Checked whether the company/domain-blocking work (commit ea75aad, "auto-block big-tech companies") touches this hierarchy -- it doesn't. `git show ea75aad --stat` touches app/models/company.rb and JobBoards::Syncer::CompanyResolver only; Domain/root_domain_id is untouched. My original task description's speculation that this hierarchy might back the blocklist was wrong -- correcting that here.
- Conclusion: there is no current query pattern to serve, on ltree OR on the hierarchy column itself. Adopting ltree now would mean building path-query capability for a hierarchy nothing queries yet -- pure speculative engineering. Per the ladder (does this need to exist at all?), the honest answer is no. Remove the extension; the root_domain_id column/index question is a separate, larger scope decision (whether Domain hierarchy itself is dead code) that this task does not own -- flagging it as a possible follow-up, not resolving it here.

Execution: generated `db/migrate/20260808161826_disable_unused_ltree_extension.rb` via `bin/rails generate migration DisableUnusedLtreeExtension`, body is `disable_extension "ltree"` in a `change` method (Rails' extension migration methods are self-reversible, no explicit up/down needed). Next: run `bin/rails db:migrate`, confirm schema.rb drops the enable_extension line and version bumps, run full RSpec suite, finalize.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified the migration is genuinely reversible: ran bin/rails db:rollback (confirmed ltree re-enabled via pg_extension query), then re-ran bin/rails db:migrate to restore the intended final state on both dev and test databases.

AC #2 (adopt path) is N/A -- the decision was to remove, documented in the plan with the investigation that led there, including a correction of a wrong assumption in this task's own description (root_domain_id is not used by the big-tech blocklist logic; it's not used anywhere).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Decision: removed the unused `ltree` Postgres extension rather than adopting it.

**Investigation:** confirmed via repo-wide grep that ltree has zero references in app/ or packages/. Went further than the original audit: the one hierarchy structure that could have justified ltree (`domains.root_domain_id`) also has zero references anywhere -- no association even declared on the Domain model, let alone a query using it. Checked whether the big-tech company-blocking work (ea75aad) uses this hierarchy -- it doesn't (touches Company/CompanyResolver only). Adopting ltree now would mean building path-query capability for a hierarchy nothing currently queries -- speculative engineering with no driving use case.

**Changed:** db/migrate/20260808161826_disable_unused_ltree_extension.rb (new, `disable_extension "ltree"` in a `change` method -- self-reversible).

**Verified:**
- Migrated both dev and test databases; schema.rb no longer lists ltree, version bumped to 2026_08_08_161826.
- Confirmed reversibility explicitly: rolled back (ltree re-enabled, verified via pg_extension), re-migrated (dropped again, verified).
- Full RSpec suite (root + packages/ingestion): 603 examples, 0 failures.

**Follow-up flagged, not resolved here (out of this task's scope):** `domains.root_domain_id` itself (column + index) is unused dead schema independent of ltree. Worth a separate decision on whether to remove it too, or whether it's intentionally reserved for near-term work -- didn't assume either way since that's a different, larger-scope question than "is ltree used."
<!-- SECTION:FINAL_SUMMARY:END -->
