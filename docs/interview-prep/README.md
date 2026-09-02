---
name: interview-prep-docs
description: >-
  Index for the interview prep pack feature docs — the read-aloud standard,
  the text-to-speech tool prompt, and the per-role worked references.
metadata:
  type: reference
  version: 1.0.0
---

# Interview prep docs

The `interview-prep` skill generates a **prep pack** per job posting: role setup,
domain primer, story arc, company hooks, referral play, likely questions,
questions to ask, night-before checklist. It ships in two versions, same content:

- **Human** — `UserJobPosting#interview_prep_pack`, the default render on the job posting page
- **Read-aloud** — `UserJobPosting#interview_prep_pack_spoken`, a `SpokenRewriter` pass for text-to-speech

## What's here

| File | What it is |
|---|---|
| [`tts-readable-documentation.md`](tts-readable-documentation.md) | The standard the read-aloud version is authored to and the `interview-prep-auditor` checks against |
| [`tts-transform-prompt.md`](tts-transform-prompt.md) | Copy-paste instruction block for whatever tool turns a `*_spoken` file into speech, closed captions, or a lyrics transcript |
| `<role>/` | One subdirectory per role Mike interviews for |

## Per-role subdirectories

Each role gets its own subdirectory, named for the company (and disambiguated by
role where a company has more than one opening):

| Subdirectory | Role |
|---|---|
| [`basis-dsp/`](basis-dsp/) | Basis Technologies — Senior Software Engineer, Basis Platform / DSP |

A subdirectory holds:

- `reference.md` — a hand-written prep pack for that posting, the quality bar the
  generated pack is measured against. Part 1 is what "good" looks like; Part 2 is
  the per-section spec.

The generated pack itself lives on the `UserJobPosting` and renders on the posting
page; it is not committed here.
