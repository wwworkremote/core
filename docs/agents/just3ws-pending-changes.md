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

## 1. `klobomedia` has no `type:` — blocked on Mike

The only position file still missing one. Not contract and not full-time: sweat-equity
startup, Mike was CTO, working days at ReachLocal concurrently. Candidate values `Founder`,
`Advisory`, `Part-time`, or omit and let the summary carry it.

Asked as HUMAN.md #4.

## 2. `tandem` conflicts with what Mike answered — blocked on Mike

`_data/resume/positions/tandem.yml` says `type: Contract`. Mike's HUMAN.md round-1 answer
listed **tandem as full-time**.

The `26d528bd` type-setting commit did not touch tandem, so its `Contract` value predates
that pass and was never reconciled against the answer. **Do not silently pick one.** One of
the two is wrong and only Mike knows which.

## 3. EMR-Bear reframe — blocked on Mike

Current: `title: Development Manager`, `type: Full-time`, `start_date: May 2026`.

The original draft (`Interim Development Manager (90-Day Engagement)`, `type: Contract`) is
**withdrawn** — Mike confirmed it was full-time, and "interim" understates the work.

Revised proposal, pending his approval as HUMAN.md #5:

```yaml
title: Development Manager — Founder Transition & Acquisition Handoff
type: Full-time          # unchanged
```

plus a `case_study` block covering the handoff scope. The importer in this repo already
reads `case_study` into `ExperienceHighlight` rows automatically.

**Public-safety constraint:** the reason the tenure was short — a disagreement with the
the acquirer — must **not** appear in the YAML. It is interview-prep material and
already lives in the vault copy.

## 4. Selected Current Work is still four entries — blocked on Mike

`_data/resume/ats.yml:25-31` lists `agent-tooling`, `wwworkremote`, `phalanx-duel`,
`technical-conversation-archive`. `resume.html` is ~1,856 words, roughly 3.7 pages.

This is downstream of a decision Mike has not made: **whether to re-open the wwworkremote
repo.** A private repo described in detail is an unverifiable claim, which is the weakest
form of a strong item. Options and the recommendation are HUMAN.md #2. Trimming the list
before that is answered would be premature.

## 5. SCNA / Obtiva / SCMC chronology — research, not a question

Three sources disagree and the corrected-history post's causal chain (SCNA → met Dave Hoover
→ Obtiva → founded SCMC) cannot hold if Obtiva started August 2009.

Mike supplied primary sources rather than an answer:

- `archive.upcoming.org/event/software-craftsmanship-north-america-scna-3067082` dates SCNA
  to **2009-08-25**, which makes SCNA and Obtiva roughly simultaneous rather than sequential.
- Wayback snapshots of `obtiva.com` (2002 first, 2005 first real, 2010-11-27 first Mike
  appearance) and `twitter.com/just3ws` (2009-02-27).
- `scna.softwarecraftsmanship.org` snapshots — Mike noted these link videos that may be
  worth adding to the SCNA interview bios.

Local copies in `~/Desktop/inbox/SCNA History/`.

**This is a research task, not a blocked one.** Work the sources, propose a corrected
timeline, and have Mike confirm only the one fact no source carries: what year SCMC actually
started (`_data/resume/leadership.yml` claims 2009). Asked as HUMAN.md #6.

## 6. KloboMedia / TheSocReport narrative — low risk, do it with #1

Mike's account: TheSocReport was the product, killed when the data taps closed — Twitter's
firehose shutdown, Facebook closing user-intelligence APIs, Instagram's APIs closing after
the acquisition. He hit the same wall again later with WWWorkRemote when GitHub, Stack
Overflow, and other job boards disabled feeds.

A product ended by a platform's API shutdown is a **market** explanation, not a failure, and
it is worth one line in the position summary.

**Public-safety constraint:** his private assessment does not go in the YAML.

---

## Recommendation

**Do 5 and 6 now; hold 1–4 for Mike; do not batch them into one commit.**

Items 1–4 are each blocked on a single answer and are cheap once given — a one-line YAML edit
apiece. Batching them means the whole set waits on the slowest answer, which is item 4, which
is itself waiting on a strategic decision about repo visibility. Ship each as it unblocks.

Item 5 is the only one with real work in it, and it needs no permission — the sources are
public and already downloaded.

**The larger point, stated plainly:** this queue is lower-value than it looks. Mike is
unemployed and the mission priority is employment. `type:` fields and a title reframe do not
generate interviews. The finding that matters more is in TASK-83's notes — **of 28 rows in
his LinkedIn tracker, only 3 existed among 6,136 ingested postings.** The system is not
surfacing the jobs he actually applies to. Fixing that changes outcomes; polishing YAML
mostly changes how a finished document reads.

Work this queue when it unblocks, not instead of that.
