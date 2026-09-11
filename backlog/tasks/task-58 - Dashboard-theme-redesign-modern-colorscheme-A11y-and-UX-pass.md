---
id: TASK-58
title: 'Dashboard theme redesign: modern colorscheme, A11y, and UX pass'
status: To Do
assignee: []
created_date: '2026-08-17 00:59'
labels: []
dependencies: []
priority: low
type: enhancement
ordinal: 64000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mike wants the current dashboard/admin theme replaced -- described it as "a bad phase in my aesthetic preferences" and wants "the most effective dashboard UI/UX," state-of-the-art colorscheme, and real accessibility (A11y) grounding, not just a re-skin.

This is a substantial, taste-driven redesign spanning every admin/dashboard view (job_postings index/show, admin/* controllers' views, the neural/cyberpunk-styled card-neural/btn-neural Tailwind classes seen throughout this session's view work). Deliberately not started same-session as a large backlog-clearing push -- deserves a fresh session with room to present actual direction/options (palette candidates, contrast-ratio-checked against WCAG AA/AAA, a component or two mocked up) before committing to a full pass, rather than guessing at "state of the art" unsupervised.

Suggested first step next session: audit current color usage (grep for the neural-* custom Tailwind classes and any hardcoded hex/oklch values), identify a small set of representative screens to mock a new palette against first (job_postings index, admin dashboard, one show page), get sign-off on direction, then roll out.
<!-- SECTION:DESCRIPTION:END -->
