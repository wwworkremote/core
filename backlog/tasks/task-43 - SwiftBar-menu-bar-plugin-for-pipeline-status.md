---
id: TASK-43
title: SwiftBar menu-bar plugin for pipeline status
status: To Do
assignee: []
created_date: '2026-08-14 17:31'
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
