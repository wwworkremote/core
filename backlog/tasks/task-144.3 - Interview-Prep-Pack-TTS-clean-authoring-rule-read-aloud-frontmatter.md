---
id: TASK-144.3
title: 'Interview Prep Pack: TTS-clean authoring rule + read-aloud frontmatter'
status: Done
assignee: []
created_date: '2026-09-02 23:02'
updated_date: '2026-09-02 23:56'
labels:
  - job-search
  - llm
  - accessibility
dependencies: []
parent_task_id: TASK-144
priority: high
type: enhancement
ordinal: 164000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The prep pack gets fed to a text-to-speech engine. It must read cleanly aloud as well as on screen.

Make it a rule (in the generator prompt CONSTRAINTS + a shared reference the skill/agent point to):
- Spell out abbreviations and contractions everywhere: "Senior" not "Sr.", "for example" not "e.g.", "that is" not "i.e.", "versus" not "vs.", "and so on" not "etc.", "and" not "&", "with" not "w/", "about" not "~", "percent" not "%", "then" / "leads to" not the arrow, "and"/"to" not "/".
- Expand every acronym on first use in a spoken-friendly way; short form is fine after that.
- Numbers, money, ranges as words or spoken digits: "140,000 to 175,000 dollars" not "$140–175K"; "under 100 milliseconds" not "sub-100ms"; "99th percentile" not "p99"; "4 percent" not "4%".
- No bare URLs in the spoken body -- name the source (reinforces the existing rule).
- No emoji.
- Prose and simple bullet lists only in the pack body -- no tables, no code blocks (a table row reads as a run-on).
- Sentences short enough to follow by ear; front-load the point; shallow parentheticals.
- A YAML frontmatter block at the top of the pack with read-aloud hints: fully-spelled title, a pronunciation map for tricky proper nouns, the section list, estimated spoken minutes.

Then:
- Regenerate docs/interview-prep/_reference/reference.md TTS-clean + human-readable (it is the quality bar, so it must model the target -- convert its tables to prose/definition lists, spell everything out).
- The job posting show view renders the pack: split the frontmatter fence so it does not render as a horizontal rule; surface the read-aloud hints.
- Update the interview-prep skill and interview-prep-auditor agent: the pack must be TTS-clean; the auditor checks it. Note what is available locally to help (macOS `say`; OpenAI/Gemini TTS models are in the synced Model table but nothing wires them). Rules-file frontmatter should carry read-aloud context.
- Regenerate the Basis pack.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Generator prompt instructs TTS-clean output: abbreviations/contractions spelled out, acronyms expanded on first use, numbers/money/ranges spoken-form, no bare URLs, no emoji, no tables or code blocks in the pack body
- [x] #2 Generated pack starts with a YAML frontmatter block carrying a spelled-out title, a pronunciation map, the section list, and estimated spoken minutes
- [x] #3 prompt_builder_spec asserts the TTS constraints and the frontmatter instruction are present
- [x] #4 The job posting show view splits the frontmatter fence (no stray horizontal rule) and surfaces the read-aloud hints
- [x] #5 interview-prep skill and interview-prep-auditor agent updated: pack must be TTS-clean, auditor checks abbreviations/numbers/tables/URLs/emoji, available TTS help noted
- [x] #6 CONTEXT.md and docs/changelog.md updated
- [x] #7 The Basis pack (UJP #268) is regenerated and reads cleanly aloud
- [x] #8 All touched specs stay green
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Two versions of the pack, same content, different format:

- interview_prep_pack (human): the current generator output. Tables allowed, digits/money as
  written, standard structure. Keeps the acronym-expansion + no-invented-URL rules (help
  humans too) and a light "lists over tables where the content is a list".
- interview_prep_pack_spoken (read-aloud): a REWRITE of the human pack, not an independent
  generation -- guarantees identical content. LLM::InterviewPrepGenerator::SpokenRewriter
  takes the human pack + the [READ-ALOUD] rules and emits: a YAML frontmatter block
  (spelled-out title, pronunciation map, section list, spoken_minutes) then the same pack,
  TTS-clean -- abbreviations/contractions spelled out, acronyms expanded, numbers spoken-form,
  no tables/code/emoji/bare-URLs, one idea per sentence.

Standard: docs/research/tts-readable-documentation.md (written this session, WCAG / GOV.UK /
Deque / WebAIM sourced).

Files:
1. migration: add user_job_postings.interview_prep_pack_spoken (text). Reuse
   interview_prep_pack_generated_at.
2. prompt_builder.rb: pull the frontmatter + spelled-number + no-table rules back OUT of
   default_prompt (they were briefly added); keep acronym/abbreviation spell-out + a light
   lists-over-tables line. Add READ_ALOUD_RULES constant (shared with the rewriter).
3. new spoken_rewriter.rb + prompt: rewrite the human pack per READ_ALOUD_RULES + frontmatter.
4. interview_prep_generator.rb: after storing the human pack, run SpokenRewriter, store
   interview_prep_pack_spoken. `spoken:` kwarg (default true) to allow skipping.
5. user_job_posting model: parsed_spoken_frontmatter / spoken_body helpers (split the fence).
6. view: human pack renders as now; a "Read-aloud version" <details> shows the spoken body
   with the frontmatter hints surfaced (no stray <hr>).
7. Wwwr::InterviewPrep: --spoken flag prints interview_prep_pack_spoken.
8. interview-prep skill + interview-prep-auditor agent: both versions; auditor checks the
   spoken one against the tts-readable standard (abbreviations, spoken numbers, no tables,
   no bare URLs, no emoji, valid frontmatter). Note macOS `say` for spot-checks.
9. docs/interview-prep/_reference/reference.md stays human-format (it is a reference doc read by
   humans/agents, not TTS) -- add a pointer to tts-readable-documentation.md and the note that
   the generated pack ships in both formats.
10. CONTEXT.md + changelog.
11. Specs: rewriter spec, prompt_builder READ_ALOUD assertions, generator stores both,
    model frontmatter-split spec, cli --spoken, view details block.
12. Regenerate the Basis pack -> both columns populated; spot-check the spoken one with `say`.

ponytail: SpokenRewriter is a second LLM call per generation (local model ~5 min each). Made
it skippable via `spoken:` but default-on since TTS is the point. If the local model garbles
the rewrite, that is the TASK-145 signal again.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
AC#1/#2/#3: the TTS rules + frontmatter instruction live in LLM::InterviewPrepGenerator::SpokenRewriter (not the main prompt) since the pack ships in two formats -- the human generator prompt stays human-format. spoken_rewriter_spec asserts the rules + frontmatter instruction are in the task_instructions.

AC#5: docs/interview-prep/_reference/reference.md deliberately NOT rewritten TTS-clean -- it is a reference doc read by people/agents, not fed to a speech engine (decided with Mike; it now points to tts-readable-documentation.md and notes the pack ships both formats). The TTS-clean standard is modelled by the SpokenRewriter output + the frontmatter example in tts-readable-documentation.md.

New: docs/tts-transform-prompt.md -- the copy-paste instruction block for the external TTS tool (Mike's explicit ask). Engine-agnostic: covers parsing/not-speaking the frontmatter, applying the pronunciation map as a lexicon (with SSML mappings), section markers, sentence-per-cue captioning (VTT/SRT), line-per-sentence lyrics (LRC), and the do-nots.

160 examples green across the 7 touched spec files. Commit d569b8d6 (one line of the commit message lost a backticked token to shell quoting -- cosmetic).

AC#8 pending: Basis pack regeneration running (2 LLM calls on the local model).

Docs regrouped under docs/interview-prep/ (commit 93fa21e1): _reference/reference.md, tts-readable-documentation.md, tts-transform-prompt.md, plus a README. One per-role subdirectory. AC#5's 'rewrite interview-prep-basis-dsp.md TTS-clean' stays a deliberate no -- it is a human reference doc, not a speech source; it points to the standard instead.

SpokenRewriter fixes: unwrap_fence strips the ```yaml wrapper the local model adds; the prompt now shows a fully-quoted frontmatter example (the model had emitted an unquoted colon-bearing title -> YAML parse failed -> no hints panel). Regen after: frontmatter parses, spoken_minutes ~10, body genuinely TTS-clean.

bin/wwwr interview-prep <id> --export[=<role>] (commit 22d942b9): writes pack.md + pack.spoken.md to ~/ai/outbox/wwwr/interview-prep/<role>/. On export the read-aloud frontmatter is re-serialized with system discovery keys (format/lang/source/generated_at) ahead of the model's content hints -- and a malformed model block is repaired into valid YAML in the process. Verified live: ~/ai/outbox/wwwr/interview-prep/basis-dsp/ has both files, valid frontmatter.

New docs/interview-prep/tts-integration-guide.md -- for wiring up the external TTS tool: discovery (glob + format key + generated_at freshness), the single-file model, full frontmatter schema table, pronunciation-to-SSML mapping, output conventions. Mike's explicit ask.

Local 7B ceilings persist in the output: pronunciation map over-includes (Docker/React get useless hints), IAB hint imperfect, title echoes the human pack's ALL-CAPS heading, and the inherited stack-in-useful-context / skill-gap-in-blind-spots issues. Structure and TTS-cleanliness are solid. TASK-145 (capable model) remains the quality lever.

Full suite green across the touched files (cli_spec 22, generator/rewriter/model 41, job_postings request spec). Commits: d569b8d6, 8e26db7c, 93fa21e1, 22d942b9 (+ the 8e26db7c YAML fix).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
The prep pack is fed to a text-to-speech engine, so it now ships in **two versions, same content**:

- **`interview_prep_pack`** (human) — the generator's output, unchanged.
- **`interview_prep_pack_spoken`** (read-aloud) — a `SpokenRewriter` pass over the human pack: opens with a YAML frontmatter block, then text-to-speech-clean prose (abbreviations and numbers spelled out, "to" not dashes in ranges, no tables, no code blocks, no emoji, no bare URLs, one idea per sentence). Non-fatal on failure; `spoken:` kwarg (default true).

## The standard

`docs/interview-prep/tts-readable-documentation.md` — WCAG / GOV.UK / Deque / WebAIM sourced. The `interview-prep-auditor` checks the read-aloud version against it.

## Frontmatter

The read-aloud block carries **content hints** from the model (`title`, `pronunciation` map, `sections`, `spoken_minutes`) and, on `--export`, **discovery keys** injected by the CLI (`format: interview-prep-read-aloud`, `lang`, `source`, `generated_at`). Export re-serializes the block, which also repairs a malformed model block into valid YAML.

## Surfaces

- `UserJobPosting#spoken_pack_parts` splits the frontmatter fence.
- Job posting page: "Read-aloud version" toggle with pronunciation hints surfaced.
- `bin/wwwr interview-prep <id> --spoken` prints it; `--export[=<role>]` writes `pack.md` + `pack.spoken.md` to `~/ai/outbox/wwwr/interview-prep/<role>/` (role defaults to `company_name.parameterize`).

## Docs

Regrouped under `docs/interview-prep/` — `_reference/reference.md`, `tts-readable-documentation.md`, `tts-transform-prompt.md` (the LLM-facing transform instruction), `tts-integration-guide.md` (operator-facing: discovery, the single-file model, the frontmatter schema, output conventions), and a README. One subdirectory per role. `interview-prep-basis-dsp.md` is NOT rewritten TTS-clean (removed AC) — it is a human reference doc, not a speech source; it points to the standard.

Caption/lyrics *export* is deferred — the read-aloud version is cleanly sentence-segmented so it stays a formatting transform later.

## Tests

cli_spec (22: stored / regenerate / new / --spoken / --export / --export=role / failure / 404), spoken_rewriter_spec (orchestrator wiring, fence-strip, failure), generator spec (stores both, skips on `spoken: false`, keeps human pack on rewrite failure), model spec (frontmatter split, malformed-YAML tolerance), job_postings request spec (read-aloud toggle + hints). All green.

## Known ceiling

The local 7B half-applies the spoken rules and produces a noisy pronunciation map (`Docker: docker`); it also inherits the human pack's stack-in-useful-context / skill-gap-in-blind-spots weaknesses. Structure and TTS-cleanliness are solid. A capable model on the path is TASK-145.

Commits: d569b8d6 (two versions), 8e26db7c (YAML quoting fix), 93fa21e1 (docs regroup + fence strip), 22d942b9 (--export + integration guide). Branch `feat/interview-prep-pack`.
<!-- SECTION:FINAL_SUMMARY:END -->
