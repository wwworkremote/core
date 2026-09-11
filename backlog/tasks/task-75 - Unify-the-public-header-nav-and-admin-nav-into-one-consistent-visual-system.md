---
id: TASK-75
title: Unify the public header nav and admin nav into one consistent visual system
status: To Do
assignee: []
created_date: '2026-08-19 19:46'
labels: []
dependencies: []
references:
  - app/views/layouts/application.html.erb
  - app/views/admin/shared/_nav.html.erb
priority: medium
type: enhancement
ordinal: 88000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The public-facing header nav (`app/views/layouts/application.html.erb`) and the admin nav (`app/views/admin/shared/_nav.html.erb`) are two visually and structurally unrelated navigation systems in the same app:

- Public: sticky `<header>`, bold "WWWorkRemote" logo, horizontal pill-style menu, two dropdown menus (Profile/Admin).
- Admin: not sticky (scrolls away), no logo/brand mark, dense multi-group inline text nav with tiny (`text-[9px]`) category labels (Core/Inventory/Engine/Intel/Mounts), a "Mounts" dropdown, an "Exit Admin" button.

A companion task (this session's nav accessibility pass) added semantic `<nav>` landmarks and active-page indication to both as a safe, non-visual-risk slice -- deliberately deferred the actual visual merge since it can't be verified without a live browser (Chrome extension was disconnected when this was scoped).

Candidates worth considering once Chrome is back and this can be visually iterated on:
- Give the admin nav the same sticky-header treatment and brand mark as the public nav, so it's recognizably "the same app."
- Reconsider the tiny (9px) uppercase category labels for legibility/contrast (not measured against WCAG contrast ratios, just flagged as small).
- Decide whether "Exit Admin" should have a visual sibling ("Enter Admin") on the public side beyond the existing Admin Menu dropdown item.
- Consider whether admin's per-page `render "admin/shared/nav"` (scrolls with content) vs. public's sticky header is an intentional distinction (admin = dense workspace, public = browsing) worth keeping, or genuinely just inconsistent.
<!-- SECTION:DESCRIPTION:END -->
