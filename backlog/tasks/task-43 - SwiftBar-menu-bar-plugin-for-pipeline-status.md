---
id: TASK-43
title: SwiftBar menu-bar plugin for pipeline status
status: Done
assignee: []
created_date: '2026-08-14 17:31'
updated_date: '2026-08-14 20:54'
labels:
  - ux
dependencies:
  - TASK-42
priority: low
type: feature
ordinal: 49000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mike already runs SwiftBar ($HOME/.swiftbar) -- an executable script dropped there with a refresh-interval-encoded filename gets rendered live in the macOS menu bar for free, no native app build needed. Thin wrapper: a script in $HOME/.swiftbar/ that shells out to bin/wwwr (task-42) status/postings and formats the output in SwiftBar/BitBar plugin syntax (menu bar summary line + dropdown detail, clickable items via SwiftBar's href/bash params for common actions like opening a posting or marking ignore).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Script lives outside the repo in $HOME/.swiftbar/ per SwiftBar convention, or the repo ships a template that gets symlinked/copied there
- [ ] #2 Menu bar shows a live pipeline summary (new postings, pending review count) refreshed on SwiftBar's own interval
- [ ] #3 Dropdown lists recent/actionable postings with at least one clickable action
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Shipped swiftbar/wwwr_status.5m.sh -- a bash wrapper around bin/wwwr formatted in SwiftBar plugin syntax (menu bar title, dropdown status block, recent-postings list, refresh action). Deliberately NOT written into $HOME/.swiftbar directly (outside the repo, would start executing on Mike's live schedule unreviewed) -- ships as a repo template per the task's AC #1, with the exact symlink command Mike needs to run to activate it in the script's own header comment. Filters Rails/OpenTelemetry boot-noise off stdout so the dropdown stays clean regardless of RAILS_ENV. Each posting row has a clickable "ignore" action wired through bin/wwwr transition -- verified live end-to-end against dev data (marked posting #207 ignored via the exact bash/param invocation SwiftBar would use, confirmed the status change, then restored it via the existing `restore` AASM event so dev data was left untouched). WWWR path is hardcoded to this machine's repo location -- unavoidable for a personal SwiftBar plugin once it's symlinked outside the repo, noted in the script.
<!-- SECTION:FINAL_SUMMARY:END -->
