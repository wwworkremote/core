---
name: indeed-profile-sync
description: "Keep Mike's Indeed profile (profile.indeed.com) aligned with his canonical resume data. Use when his resume or target archetype changes, when he starts or leaves a role, for a periodic refresh, or when he asks to check / fix / update / clean up his Indeed profile. Needs Claude-in-Chrome and Mike already logged into Indeed in Chrome."
metadata:
  version: 1.0.0
---

# Indeed profile sync

Indeed's profile is a distribution target for the canonical resume data that lives in
`just3ws` (`_data/resume/`). It drifts: Indeed's "Review suggestions" flow re-scrapes an
uploaded resume and layers duplicate work-experience entries, mis-parsed skills, and stale
summaries on top of whatever is there. This skill is the periodic reconcile — canonical is
the source of truth, Indeed gets brought back in line.

The whole thing runs against a **live logged-in account**, so it stays human-in-the-loop:
apply one section at a time, show Mike employer-facing content before saving anything
irreversible, and never touch the bulk "Approve all".

## Before you start

- Confirm Claude-in-Chrome is available and Mike is logged in at `profile.indeed.com`
  (`tabs_context_mcp`, then a fresh tab). If he isn't logged in, stop and ask him to log in —
  never enter credentials.
- Pull the canonical data (this is the sanctioned in-repo path — the app already fetches it):
  ```
  bin/rails runner 'd = Resume::Source.new.to_h; puts JSON.pretty_generate(d.slice("profile","summary","timeline","positions","skills","archetypes"))'
  ```
  `positions` is a hash keyed by slug; `timeline["history"]` is the curated order; each
  position has `title`, `company` (`{name, location}`), `start_date`, `end_date`, `summary`,
  `highlights`. `ats.skills` is the canonical skill shortlist.

## Steps

1. **Snapshot the current profile.** `get_page_text` on `profile.indeed.com/` and
   `.../preferences` and `.../profile/skills`. Save to a scratch file. This is also the input
   the `indeed-profile-auditor` agent diffs, if you want the gap analysis done context-isolated.

2. **Diff against canonical → gap list.** Per section: what's stale, wrong, missing,
   duplicated. Split each gap into **mechanical** (title/date/company/bullet mismatch, an
   obvious dead entry, a missing role that's in `timeline`) vs **judgement** (which archetype,
   the comp floor, whether to list a 1-month gig, how to represent the current independent
   period, reconciling an Indeed-only entry against canonical). Surface the judgement calls to
   Mike; don't decide them.

3. **Apply, section by section**, verifying each save with a screenshot or `get_page_text`:

   - **Work experience** — each entry edits at `profile.indeed.com/profile/experience/<id>`;
     get the ids from `read_page` (filter `interactive`) — the "Edit …" links carry them.
     Add a role at `/profile/experience/add`. Fields: title/company/city are text comboboxes
     (type, then `Escape` to dismiss the autocomplete; for city, click the matching suggestion
     row). Descriptions are a plain textbox — click in, `cmd+a`, `Delete`, type. Write bullets
     from the position's `summary` + `highlights`, one per line. Indeed auto-sorts entries by
     date.
   - **Summary** — edit on the profile page. Canonical `summary`, or accept the summary that
     Indeed's sync suggests from a freshly-uploaded archetype resume (that one case is worth
     taking — see step 4).
   - **Preferences** — `.../preferences`, each row has an edit pencil. Work areas → engineering
     / IT only. Min base pay is a filter, not a negotiation number — ask Mike for it. Delete
     the "Work schedule" (shift) preference; it reads blue-collar for a salaried remote role.
   - **Skills** — `.../profile/skills`, one deletable chip per skill. Curate hard toward
     `ats.skills` plus concrete technologies recruiters keyword-search (languages, datastores,
     AWS/K8s/Docker, observability) and Mike's signature phrases. Cut design-pattern names,
     `(data structure)` / `(System development task)` entries, dead VCS, redundant "System X"
     variants, and near-duplicates. ~40-50 relevant beats 150 grapeshot.
   - **Links / contact** — GitHub + `just3ws.com` + LinkedIn. Contact edits at `/edit/contact`.

4. **Resume file.** Indeed holds exactly **one uploaded file** plus one auto-built "Indeed
   Resume". A new upload replaces the old — there is no multi-resume library. **You cannot do
   the upload** (the file isn't in a path the upload tool can reach); Mike uploads the right
   archetype PDF from `just3ws.github.io/exports/resumes/` himself. You can delete the old one
   (`.../files` → the file's `…` menu → Delete; the structured Indeed Resume covers the gap).
   After Mike uploads, the sync banner regenerates — handle it per the rule below.

## Browser-automation mechanics (the part that bites)

- **Date `<select>` fields don't take `form_input` or keyboard typeahead reliably** — React
  reverts the value. Set them with the native setter + a real change event via
  `javascript_tool`:
  ```js
  const setSel = (idx, val) => {
    const el = document.querySelectorAll('select')[idx];
    Object.getOwnPropertyDescriptor(Object.getPrototypeOf(el), 'value').set.call(el, val);
    el.dispatchEvent(new Event('input', {bubbles: true}));
    el.dispatchEvent(new Event('change', {bubbles: true}));
  };
  // select order on an experience form: 0=From month, 1=From year, 2=To month, 3=To year
  setSel(0, 'SEPTEMBER'); setSel(1, '2018'); setSel(2, 'DECEMBER'); setSel(3, '2018');
  ```
  Month values are uppercase (`SEPTEMBER`); year values are the plain string (`2018`).
- **Deleting a chip / entry / preference has only a transient "Undo" toast**, not a permanent
  undo. Confirm the target before clicking, especially in the skills list which reindexes after
  each delete — target delete buttons by `aria-label="Delete <name>"`, not by position.
- **`read_page` output can be one render stale** after a JS mutation — re-check with a
  screenshot or a fresh `javascript_tool` read before concluding a change didn't take.
- Bulk deletes across the skills list: a `javascript_tool` loop clicking
  `button[aria-label^="Delete "]` one at a time with a ~350ms `await` between clicks is
  reliable; verify the count and the survivors afterward, then reload to confirm it persisted
  server-side.

## The "Review suggestions" / "Sync to profile" rule

**Never click "Approve all".** That flow bundles skill suggestions with **re-adding duplicate
and outdated work-experience entries** and swapping the summary — it is exactly what creates
the mess this skill cleans up.

If the sync banner is showing and Mike wants something from it:
- Open it read-only first (`profile.indeed.com/import`, `get_page_text`) and report what it
  actually proposes.
- Accept **per card** (each has its own "Save to profile" ✓). The Work-experience section has
  a `…` menu with **"Dismiss all"** — use that to reject every work-exp suggestion in one
  click.
- A freshly-uploaded archetype resume usually yields ~13 suggestions: the summary (often worth
  taking), ~10 duplicate work-exp entries (Dismiss all), and a mis-parsed "MCP" certification
  (dismiss). Skills usually come back clean / "Reviewed" — nothing to do.

## Non-goals / boundaries

- **Do not edit or commit anything in `just3ws`** (see memory `feedback_stay_in_this_repo`).
  Canonical resume changes happen there, by Mike, on his terms — this skill only reads canonical
  and pushes it *to Indeed*.
- The content judgement calls are Mike's: which archetype resume, the salary floor, whether a
  short engagement is worth listing, how to frame the independent period, whether an
  Indeed-only role (e.g. a post-transition consulting gig) should be added to canonical or
  dropped from Indeed.
- Not a general "apply to jobs" flow — that's `docs/agents/application-submission-workflow.md`.
