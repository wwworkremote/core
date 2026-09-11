---
id: TASK-48
title: >-
  quality.yml still red: Rails Best Practices (66 warnings) + Database
  Consistency (~50 findings)
status: To Do
assignee: []
created_date: '2026-08-16 12:42'
labels:
  - ci
  - tech-debt
dependencies: []
references:
  - .github/workflows/quality.yml
  - lib/tasks/quality.rake
priority: medium
type: chore
ordinal: 54000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Quality Assurance GHA workflow has failed on every push since at least 2026-08-12 (6+ consecutive runs). Investigated as part of "get GHA to a clean green build" -- fixed one real bug (Traceroute rake task missing entirely under RAILS_ENV=test, a Gemfile-group misconfiguration, separate commit) but two more of `rake quality`'s checks are genuinely failing with real, pre-existing, repo-wide findings, not misconfiguration:

1. **Rails Best Practices**: 66 warnings across the whole app -- law of demeter violations, "move model logic into model" (fat controllers), unused public methods (BoardQuery, JobPosting, LLMMessagesHelper and others), route customization overuse in config/routes.rb, time_ago_in_words style suggestions across several admin views.
2. **Database Consistency**: ~50 findings -- missing uniqueness validators backing real unique DB indexes (HackerNews::Item, User#email, Domain#name, JobPostingTrend, and more), several genuinely redundant indexes (TargetDomain has two indexes each covering the other; ResumeSkill, JobPosting, Resume each have a narrower index made redundant by a wider one), missing NOT NULL on columns that are never actually nullable in practice (SystemSetting#key, Company#name/#slug, InterviewTask#title/#status, and others), two primary keys still int/serial instead of bigint (HackerNews::Item, HackerNews::V0::Jobstory), several missing foreign keys (Ahoy::Visit#user, Ahoy::Event#visit/#user, Resume#parent) and missing on_delete cascade/nullify options where a dependent option is already set in the model.

Neither of these is safe to blind-fix: several of the Database Consistency findings are schema/migration changes (NOT NULL backfills, foreign key additions, dropping a redundant index) that need real data-safety review before touching a production database, not something to fix reflexively just to turn a CI badge green. Rails Best Practices findings are mostly legitimate but touch dozens of files across the whole app -- worth doing as a deliberate pass, not a drive-by.

Scope for whoever picks this up: triage each finding as real-and-worth-fixing vs. a false positive / acceptable tradeoff (record a .rails-database-consistency.yml or rails_best_practices.yml suppression with a reason, matching how config/brakeman.ignore already works in this repo, for anything intentionally not fixed) before touching any schema. Consider splitting into two sub-tasks (Rails Best Practices pass, Database Consistency pass) given the different risk profiles.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every Rails Best Practices warning is either fixed or has a recorded, reasoned suppression
- [ ] #2 Every Database Consistency finding is either fixed (with a reviewed migration for any schema change) or has a recorded, reasoned suppression
- [ ] #3 quality.yml passes on a clean push
- [ ] #4 No production data-loss risk introduced by any NOT NULL backfill or index change -- each schema-touching fix is reviewed for existing NULL/duplicate data before the migration runs
<!-- AC:END -->
