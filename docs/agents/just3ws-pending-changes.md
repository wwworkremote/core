# Pending changes in the just3ws.github.io repo

Work that belongs in the peer repo (`~/github.com/just3ws/just3ws.github.io`), queued rather
than applied. Mike asked for these to be documented and held.

**Read [`peer-contract-just3ws.md`](peer-contract-just3ws.md) first** for the authority
boundaries. The short version: that repo is **public**, so nothing here may carry the raw
career narrative behind it — the neutral form goes in the YAML, the real version stays in
`~/my/vaults/personal/Conversations/`.

State below was verified against that working tree on 2026-08-23 (clean, `d9f06f07`), not
recalled. Re-verify before acting — it has its own agents committing to it.

---

## Already done — do not redo

Checked before queueing anything, because most of this list turned out to be finished.

| Change | Commit |
|---|---|
| `type:` set on 11 positions | `26d528bd` |
| Phalanx Duel title + dates | `381fca81` |
| `agent-tooling` + `technical-conversation-archive` positions added | `be223ffb` |
| EMR-Bear + OneMain ATS-terminology pass | `ed124ed2` |

`activecampaign`, `bp`, `coderwall`, `motorola`, `riverpoint`, `trippe` already carried
`type: Contract` from before that pass. 28 of 29 position files now have a `type`.

---

## 1. `klobomedia` has no `type:` — **unblocked, apply `Founder`**

The only position file still missing one. Not contract and not full-time: sweat-equity
startup, Mike was CTO, working days at ReachLocal concurrently.

Answered 2026-08-23 (`HUMAN.answered.md` #4): **`type: Founder`**. Accurate for sweat-equity
CTO work, and reads as ownership rather than as a gap beside the concurrent ReachLocal role.

## 2. `tandem` conflicts with the YAML — **unblocked, `Contract` → `Full-time`**

`_data/resume/positions/tandem.yml:6` says `type: Contract`. The `26d528bd` type-setting
commit did not touch tandem, so that value predates the pass and was never reconciled.

Answered 2026-08-23 (`HUMAN.answered.md` #4): **the file is wrong.** It was full-time; Mike
labelled it contract himself only because the tenure was short.

Two further facts from that answer belong in the YAML, both neutral enough for a public repo:

- **Tandem is the rename of DevMynd.** Worth surfacing so a search on either name resolves to
  the same position.
- He was brought into an **over-committed engagement following an a team transition**.
  The turnaround framing is a strength.

**Public-safety constraint:** his characterisation of the engagement, the payout, and the
walkout attribution stay out of the YAML. Interview-prep material, already in the vault.

## 3. EMR-Bear reframe — **unblocked, approved**

Current: `title: Development Manager`, `type: Full-time`, `start_date: May 2026`.

The original draft (`Interim Development Manager (90-Day Engagement)`, `type: Contract`) is
**withdrawn** — it was full-time, and "interim" understates the work.

Approved 2026-08-23 (`HUMAN.answered.md` #5):

```yaml
title: Development Manager — Founder Transition & Acquisition Handoff
type: Full-time          # unchanged
```

plus a `case_study` block covering the handoff scope. The importer in this repo already
reads `case_study` into `ExperienceHighlight` rows automatically.

**Why the longer title, since Mike asked:** a reader scanning a 4-month tenure is deciding
whether he left or was removed. A bare `Development Manager` invites the bad reading; naming
the mandate answers it before the question forms.

**Public-safety constraint:** the reason the tenure was short — a disagreement with the
the acquirer — must **not** appear in the YAML. It is interview-prep material and
already lives in the vault copy.

## 4. Selected Current Work is still four entries — partially unblocked

`_data/resume/ats.yml:25-31` lists `agent-tooling`, `wwworkremote`, `phalanx-duel`,
`technical-conversation-archive`. `resume.html` is ~1,856 words, roughly 3.7 pages.

**Settled 2026-08-23** (`HUMAN.answered.md` #2): the wwworkremote repo **stays private**.
Extracting a public slice is off the table — guardrails and application data live in one
repo, so exposing any of it exposes all of it.

**Still open** as `HUMAN.md` #8: his answer was "don't put it on the resume publicly yet but
don't delete the references", which points both ways for this file. Proposed reading — keep
the `wwworkremote` entry, drop any repo URL, describe it plainly — pending one-word
confirmation. Do not edit `ats.yml` until that lands.

## 5. SCNA / Obtiva / SCMC chronology — research, not a question

Three sources disagree and the corrected-history post's causal chain (SCNA → met Dave Hoover
→ Obtiva → founded SCMC) cannot hold if Obtiva started August 2009.

Mike supplied primary sources rather than a date (`HUMAN.answered.md` #6), which is better:

| Source | Date |
|---|---|
| Obtiva start (his resume) | August 2009 |
| SCNA — `archive.upcoming.org/event/software-craftsmanship-north-america-scna-3067082` | 2009-08-25 |
| SCMC on Twitter — `twitter.com/scmchenry` | November 2009 |
| McHenry Cloud Developer's Group post (predecessor group) | 2010-01-13 |
| `scmc.gathers.us` first snapshot | 2011-01-12 |
| `mchenry.softwarecraftsmanship.org` first snapshot | 2011-01-22 |
| Earliest posted gathers.us event (Clojure Koans) | 2011-04-15 |

Plus Wayback snapshots of `obtiva.com` (2002 first, 2005 first real, 2010-11-27 first Mike
appearance) and `twitter.com/just3ws` (2009-02-27), and `scna.softwarecraftsmanship.org`
snapshots — Mike noted these link videos that may be worth adding to the SCNA interview bios.

**The published causal chain cannot hold.** "SCNA → met Dave Hoover → Obtiva → founded SCMC"
requires SCNA to precede Obtiva. Both are August 2009; they are simultaneous.

**November 2009 is the load-bearing fact.** The `@scmchenry` account is the earliest hard
evidence SCMC existed, which makes `leadership.yml`'s 2009 defensible. **Do not read the 2011
snapshots as founding dates** — they date when SCMC got *listed* on gathers.us and
softwarecraftsmanship.org, not when it started. Conflating the two is the error to avoid.

Also captured, useful for the community history rather than the resume: SCMC first hosted on
**gathers.us**, a community-building site by Ryan Briones and Ethan Gunderson (both of whom
Mike interviewed); **Jim Breen** worked with him at Obtiva on the Sears Commercial engagement.
Meetup is `software-craftsmanship-mchenry-county`.

Local copies in `~/Desktop/inbox/SCNA History/`.

**This is a research task, not a blocked one.** Work the sources and propose a corrected
timeline. If a fact turns out genuinely undecidable from them, ask it as a new numbered
HUMAN.md question rather than guessing.

## 6. KloboMedia / TheSocReport narrative — **approved, do it with #1**

Mike's account: TheSocReport was the product, killed when the data taps closed — Twitter's
firehose shutdown, Facebook closing user-intelligence APIs, Instagram's APIs closing after
the acquisition. He hit the same wall again later with WWWorkRemote when GitHub, Stack
Overflow, and other job boards disabled feeds.

A product ended by a platform's API shutdown is a **market** explanation, not a failure.
Approved 2026-08-23 (`HUMAN.answered.md` #4) as one line in the position summary.

**Public-safety constraint:** his private assessment does not go in the YAML.

---

## Recommendation

**Updated 2026-08-23 after Mike's answers.** Items 1, 2, 3, 6 are now unblocked; item 5 never
needed permission; only item 4 still waits, on `HUMAN.md` #8.

**Do not batch them into one commit.** Each is an independent fact about a different position,
and one commit per item keeps a wrong call revertible on its own. That mattered more when they
were blocked on different answers, but it still holds.

**The larger point, restated honestly:** this queue is lower-value than it looks. Mike is
unemployed and the mission priority is employment; `type:` fields and a title reframe do not
generate interviews.

**A claim previously made here is withdrawn.** This section argued the thing that mattered more
was TASK-83's finding — of 28 LinkedIn tracker rows, only 3 existed among 6,136 ingested
postings — read as "the system is not surfacing the jobs he actually applies to." Mike's answer
(`HUMAN.answered.md` #7) dissolves it: he was applying while ingestion was still being built
out, so the disjointness is chronology, not a targeting defect. **Do not retune ingestion
against those 14 applications as ground truth** — that would tune the corpus toward a sample
predating the corpus.

What survives: the funnel is still built on a partial application set, because two of five
exports captured nothing (`HUMAN.md` #1). That is the live problem, and this queue should not
displace it.
