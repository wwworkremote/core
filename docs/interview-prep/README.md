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
| [`tts-transform-prompt.md`](tts-transform-prompt.md) | Copy-paste instruction block for whatever tool turns a `pack.spoken.md` into speech, closed captions, or a lyrics transcript |
| [`tts-integration-guide.md`](tts-integration-guide.md) | For wiring up that tool: where the files land, the single-file model, the frontmatter schema for discovery and pronunciation, output conventions |
| `<role>/` | One subdirectory per role Mike interviews for |

## Exporting a pack

```bash
bin/wwwr interview-prep <job_posting_id> --export[=<role>]
```

Writes `pack.md` (human) and `pack.spoken.md` (read-aloud, with discovery
frontmatter) to `~/ai/outbox/wwwr/interview-prep/<role>/`. `<role>` defaults to
the company name parameterized. These are generated artifacts outside the repo.

## The quality-bar reference

[`_reference/reference.md`](_reference/reference.md) is the hand-written prep pack
the generated packs are measured against — the `interview-prep-auditor` diffs
against it and the generator's section structure mirrors it. Part 1 is a fully
**synthetic** worked example (invented company, role, candidate, referrer) so it
can live in the repo without carrying real interview prep; Part 2 is the
per-section spec.

Real generated packs live on the `UserJobPosting` and render on the posting page;
they are not committed here. `--export` writes them to `~/ai/outbox/`, outside the
repo.
