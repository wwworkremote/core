---
name: backlog-audit
description: "Audit Backlog.md task hygiene: find duplicate tasks, stale bug reports whose root cause was already fixed elsewhere, and mismatched embedded self-references in titles. Use when the user asks 'is the backlog clean', 'are all the tasks up to date', 'audit the backlog', or before a planning session where stale/duplicate tasks would waste a sequencing decision."
metadata:
  version: 1.0.0
---

# Backlog Audit

A Backlog.md task list drifts: two tasks get filed for the same underlying bug from different
angles, or a task sits in To Do for months after its root cause was fixed as a side effect of
unrelated work. This skill is the process for finding both, verified against the actual current
code/git state — not just re-reading task descriptions at face value.

## Steps

1. **List everything open.** `mcp__backlog__task_list` for To Do + In Progress, and
   `mcp__backlog__milestone_list` for milestone shape. Note task count, priority spread, and
   which tasks belong to an active milestone vs. free-floating.

2. **For each bug-type task older than a few weeks, check if it's already fixed.** This is the
   step that's easy to skip and the one that matters most:
   - Read the task's **References** field and `git log --oneline -- <that file>` — if a commit
     after the task's creation date touches the exact function/config the task describes, read
     that commit and check whether it already addresses the root cause.
   - `git log -p -- <file>` on a specific value the task complains about (a hardcoded string, a
     wrong default) — confirm whether that value still exists in history *after* the task was
     filed, not just whether it exists *now*.
   - If it looks fixed, verify live before closing (run the referenced spec across several
     random seeds, or reproduce the described symptom directly) — don't close on git-archaeology
     alone. See TASK-33 for a worked example: the task's root cause (a hardcoded model name) had
     already been fixed 3 months before the task was filed; the fix just never got linked back.

3. **Look for duplicates.** Cross-reference tasks whose References overlap on the same spec file
   or the same error message/symptom. Two tasks with the same failing spec and the same root
   cause are one task — close the weaker one (less-investigated, less specific) as a duplicate
   pointing at the stronger one, don't just delete it.

4. **Check for title/ID drift.** Some tasks embed a self-reference in the title (`"TASK-13: ..."`)
   that can go stale if the task was renumbered or is a leftover copy-paste from a template. The
   task's real ID (from the filename/`task_view` header) is always the source of truth — flag a
   mismatch as a hygiene note, it's cosmetic, not worth a priority bump on its own.

5. **Sanity-check priority and sequencing**, not just correctness:
   - Does a High-priority task actually block other work, or is it High because it *felt*
     urgent when filed?
   - Are there tasks whose acceptance criteria describe a data-risk change (schema edits, bulk
     updates) that shouldn't be bundled into a "quick fix" pass? Flag those as needing a
     dedicated session, don't silently scope them into whatever's being worked on.

6. **Report a punch list**, not a wall of task IDs: what's clean, what got closed as
   duplicate/stale (with the task IDs and why), and what's recommended next in priority order.

## Non-goals

This is a hygiene pass, not a planning session — it surfaces what to work on next, it doesn't
decide the roadmap. Don't invent new tasks during an audit unless a real gap surfaces (e.g. a bug
found while verifying another task's fix) — file those separately and say so explicitly, don't
let scope creep into "also I built X while I was in there."
