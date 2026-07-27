---
id: TASK-16
title: Bump Ruby 4.0.2 -> 4.0.6 to match mise platform standard
status: To Do
assignee: []
created_date: '2026-07-27 17:27'
labels: []
dependencies: []
references:
  - .ruby-version
  - .tool-versions
  - Gemfile
  - Dockerfile.prod
priority: medium
ordinal: 16000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
zdots/mise now standardizes on Ruby 4.0.6, but this repo pins 4.0.2/4.0.1 in four places. Bump and run full test suite to confirm no regressions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 .ruby-version updated to 4.0.6
- [ ] #2 .tool-versions ruby line updated to 4.0.6
- [ ] #3 Gemfile ruby directive updated to 4.0.6
- [ ] #4 Dockerfile.prod RUBY_VERSION arg updated to 4.0.6
- [ ] #5 bundle exec rspec passes after the bump
<!-- AC:END -->
