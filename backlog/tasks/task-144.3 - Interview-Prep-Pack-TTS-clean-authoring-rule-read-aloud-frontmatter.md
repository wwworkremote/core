---
id: TASK-144.3
title: 'Interview Prep Pack: TTS-clean authoring rule + read-aloud frontmatter'
status: In Progress
assignee: []
created_date: '2026-09-02 23:02'
updated_date: '2026-09-02 23:07'
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
- Numbers, money, ranges as words or spoken digits: "[posted band]" not "[posted band]"; "under 100 milliseconds" not "sub-100ms"; "99th percentile" not "p99"; "4 percent" not "4%".
- No bare URLs in the spoken body -- name the source (reinforces the existing rule).
- No emoji.
- Prose and simple bullet lists only in the pack body -- no tables, no code blocks (a table row reads as a run-on).
- Sentences short enough to follow by ear; front-load the point; shallow parentheticals.
- A YAML frontmatter block at the top of the pack with read-aloud hints: fully-spelled title, a pronunciation map for tricky proper nouns, the section list, estimated spoken minutes.

Then:
- Regenerate docs/research/interview-prep-basis-dsp.md TTS-clean + human-readable (it is the quality bar, so it must model the target -- convert its tables to prose/definition lists, spell everything out).
- The job posting show view renders the pack: split the frontmatter fence so it does not render as a horizontal rule; surface the read-aloud hints.
- Update the interview-prep skill and interview-prep-auditor agent: the pack must be TTS-clean; the auditor checks it. Note what is available locally to help (macOS `say`; OpenAI/Gemini TTS models are in the synced Model table but nothing wires them). Rules-file frontmatter should carry read-aloud context.
- Regenerate the Basis pack.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Generator prompt instructs TTS-clean output: abbreviations/contractions spelled out, acronyms expanded on first use, numbers/money/ranges spoken-form, no bare URLs, no emoji, no tables or code blocks in the pack body
- [ ] #2 Generated pack starts with a YAML frontmatter block carrying a spelled-out title, a pronunciation map, the section list, and estimated spoken minutes
- [ ] #3 prompt_builder_spec asserts the TTS constraints and the frontmatter instruction are present
- [ ] #4 The job posting show view splits the frontmatter fence (no stray horizontal rule) and surfaces the read-aloud hints
- [ ] #5 docs/research/interview-prep-basis-dsp.md is rewritten TTS-clean and human-readable: no tables in the prose sections, abbreviations/numbers spelled out, still well-structured with headings and lists
- [ ] #6 interview-prep skill and interview-prep-auditor agent updated: pack must be TTS-clean, auditor checks abbreviations/numbers/tables/URLs/emoji, available TTS help noted
- [ ] #7 CONTEXT.md and docs/changelog.md updated
- [ ] #8 The Basis pack (UJP #268) is regenerated and reads cleanly aloud
- [ ] #9 All touched specs stay green
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
9. docs/research/interview-prep-basis-dsp.md stays human-format (it is a reference doc read by
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
