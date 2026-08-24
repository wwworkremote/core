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

## 1. `klobomedia` has no `type:` — **APPLIED 2026-08-24** (just3ws `6ea30b5e`)

Confirmed again in zdots round 2 (B1). It was load-bearing, not cosmetic: `Full-time`
would have asserted a real 18-month simultaneous full-time overlap with ReachLocal
(Mar 2015 – Sep 2016). Checked after the change — no true Full-time overlaps remain;
the other apparent ones are month-adjacency, a role ending and the next starting in the
same month. All 29 position files now carry a `type`.

The only position file still missing one. Not contract and not full-time: sweat-equity
startup, Mike was CTO, working days at ReachLocal concurrently.

Answered 2026-08-23 (`HUMAN.answered.md` #4): **`type: Founder`**. Accurate for sweat-equity
CTO work, and reads as ownership rather than as a gap beside the concurrent ReachLocal role.

## 2. `tandem` conflicts with the YAML — **APPLIED 2026-08-24** (`6ea30b5e`, `a120e292`)

`Full-time` set, and both further facts landed: `company.also_known_as: DevMynd`, and a
summary line saying he was brought into an over-committed engagement following an
a team transition. Public-safety constraint honoured — no characterisation, no
payout, no attribution for the departure.

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

## 3. EMR-Bear reframe — **TITLE APPLIED, `case_study` WITHDRAWN 2026-08-24**

Title applied in `ab3dddf6`. The `case_study` half is **withdrawn** by a later answer
(zdots round 2, B5): *"I don't have any numbers for EMR-Bear. Take it off the case study.
I'll have to figure out a replacement later. Just OMF for now."*

`6ea30b5e` removed the `emr-bear-stabilization` entry from `_data/case_studies.yml` and
the two hardcoded proof cards it fed on `/case-studies` (130+ Clinics / zero clinical
outages, 36+ Vendors), plus the Governance tab they were the only members of.
**Do not add a `case_study` block to `emr-bear.yml`.** OneMain is the only position with one.

Still carrying unsourced "130+ clinics" outcome language, flagged to Mike rather than
edited unilaterally — resume self-representation is his call: `positions/emr-bear.yml`,
`_data/engagements.yml`, `exports/resume.md`, and the briefs under `docs/`.

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

## 4. Selected Current Work — **APPLIED 2026-08-24** (just3ws `620f5f84`)

`wwworkremote` removed from `_data/resume/ats.yml`. Three entries remain: `agent-tooling`,
`phalanx-duel`, `technical-conversation-archive`. `bin/validate_data.rb` passes.

**Settled 2026-08-23** (`HUMAN.answered.md` #2): the repo **stays private**. Extracting a
public slice is off the table — guardrails and application data live in one repo, so exposing
any of it exposes all of it.

**Decided 2026-08-24** (`HUMAN.answered.md` #8): remove it from the resume. This **overrules
the proposed reading** in an earlier revision of this file, which was "keep the entry, drop the
URL". He chose removal, and it is the more consistent call — a private repo described in detail
is an unverifiable claim regardless of whether a URL is attached.

**`positions/wwworkremote.yml` is deliberately retained.** "Don't delete the references" means
the position file stays, so the work is recoverable if he later opens the repo. Only the
`ats.yml` listing went. Do not garbage-collect it as an orphan.

## 5. SCNA / Obtiva / SCMC chronology — **ACTED ON 2026-08-24** (`6ea30b5e`)

The false causal chain is gone from both artifacts (`_posts/2026-08-16-history-of-
software-craftsmanship-in-chicago.md` and `chicago-craftsmanship/index.html`). Round 2
B3 added a primary source this table lacked: **Obtiva Corporation incorporated
2005-08-24** (Illinois SoS, file 64384775), and Obtiva co-organised SCNA with 8th Light
from the start — so Obtiva long predates both dates below.

The replacement asserts no ordering, because per those dates there is none to assert:
*"Obtiva and 8th Light organized that first SCNA together, and I had joined Obtiva that
August."* Deliberately did **not** swap one tidy narrative for another.

### The research that established this

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

## 6. KloboMedia / TheSocReport narrative — **APPLIED 2026-08-24** (`3d2a81de`)

One summary line naming the specific taps that closed (Twitter firehose, Facebook and
Instagram user-intelligence APIs). Public-safety constraint honoured — his assessment of
the founders is not in the YAML.

Mike's account: TheSocReport was the product, killed when the data taps closed — Twitter's
firehose shutdown, Facebook closing user-intelligence APIs, Instagram's APIs closing after
the acquisition. He hit the same wall again later with WWWorkRemote when GitHub, Stack
Overflow, and other job boards disabled feeds.

A product ended by a platform's API shutdown is a **market** explanation, not a failure.
Approved 2026-08-23 (`HUMAN.answered.md` #4) as one line in the position summary.

**Public-safety constraint:** his private assessment does not go in the YAML.

---

## Recommendation

**Queue closed 2026-08-24.** Items 1, 2, 4, 5, 6 are applied; item 3 is applied in part — its
`case_study` half was withdrawn by a later answer, so do not resurrect it. **Nothing here is
blocked on Mike any more.** Keep this file as the record of what was decided and why; new peer-
repo work should start a fresh queue rather than reopening these.

One thing this queue did not anticipate: `Resume::YamlImporter` no longer reads that repo's
working tree at all. It fetches `http://just3ws.localhost/resume.json`, so changes there
reach this app only after a Jekyll build. Applying a YAML edit is no longer sufficient to
see it here.

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
