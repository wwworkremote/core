---
id: TASK-16
title: Bump Ruby 4.0.2 -> 4.0.6 to match mise platform standard
status: Done
assignee: []
created_date: '2026-07-27 17:27'
updated_date: '2026-07-27 21:56'
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
- [x] #1 .ruby-version updated to 4.0.6
- [x] #2 .tool-versions ruby line updated to 4.0.6
- [x] #3 Gemfile ruby directive updated to 4.0.6
- [x] #4 Dockerfile.prod RUBY_VERSION arg updated to 4.0.6
- [x] #5 bundle exec rspec passes after the bump
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Bumped .ruby-version, .tool-versions, Gemfile, Dockerfile.prod, and .github/workflows/{ci,quality}.yml (not in original AC, also hardcoded 4.0.2) to 4.0.6. bundle install clean under 4.0.6. Full suite: 241 examples, 3 failures -- all pre-existing baseline (YC contract live-network 406, Bullet counter-cache warning on admin/sources), confirmed not new regressions.
<!-- SECTION:NOTES:END -->
