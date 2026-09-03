---
name: tts-readable-documentation
description: >-
  The standard a read-aloud document is authored to: how to write prose that a
  text-to-speech engine speaks cleanly without making it worse to read on
  screen, and what a YAML frontmatter block carries as read-aloud hints.
metadata:
  type: reference
  version: 1.0.0
---

# Writing documentation that reads cleanly aloud

**Doc location.** Sits in `docs/interview-prep/` with the rest of the feature's docs. It is
the standard the read-aloud version of the **interview prep pack** is authored to (the
`SpokenRewriter` pass) and the checklist the `interview-prep-auditor` agent applies. Any
repo document meant to be read by a text-to-speech engine or a screen reader follows it.

**Question.** The prep pack is fed to a text-to-speech engine. What makes prose read cleanly
aloud without making it worse to read on screen, and what can carry pronunciation hints
alongside the text?

**Short answer.** Spell everything out the way a person would say it, keep sentences short
and singular, use real sentence punctuation, prefer lists and headings over tables, and drop
anything decorative (emoji, bare URLs, symbol shorthand). A YAML frontmatter block carries
the hints a reader or a read-aloud session needs before it starts.

---

## The rules

### 1. Spell out abbreviations and contractions

A text-to-speech engine reads an abbreviation as its letters or guesses at a word. Write the
word instead, everywhere, not just on first use.

- "Senior" not "Sr.", "Junior" not "Jr."
- "for example" not "e.g.", "that is" not "i.e.", "and so on" not "etc."
- "versus" not "vs.", "approximately" or "about" not "approx." or "~"
- "and" not "&", "with" not "w/", "without" not "w/o", "number" not "No." or "#"
- "percent" not "%", "at" not "@"

This is also plain-English practice: short common words over formal or clipped ones.

### 2. Expand every acronym, and hint the hard ones

Expand each acronym in full the first time it appears. The short form is fine afterward: a
listener who has heard "Demand-Side Platform" once follows "D S P" for the rest of the
document.

For an acronym or proper noun a speech engine mispronounces, add a spoken hint in the
frontmatter pronunciation map (see below) rather than reshaping the word in the body. Do not
lean on an HTML `<abbr>` element or a screen-reader pronunciation override in prose: support
is inconsistent across engines and it degrades the experience for everyone else.

### 3. Write numbers the way they are spoken

The meaning of a number decides how it should be said, and the engine cannot tell.

- Ranges use the word "to", not a dash: "one hundred nineteen thousand to one hundred sixty
  thousand dollars", not "[posted band]". A dash in a range is read inconsistently, and "to" is
  faster to read on screen as well.
- Ordinals as words: "first", "ninety-ninth percentile", not "1st", "p99".
- Currency and units written out: "under one hundred milliseconds", not "sub-100ms".
- Large round numbers as a person says them: "roughly one hundred fifty-five million dollars
  in revenue", not "~$155M".
- Keep exact figures where they carry weight ("dropped four percent of applications") but
  write the figure as spoken.

### 4. Use real sentence punctuation, and keep sentences short

Speech engines derive pauses and intonation from periods, commas, colons, and dashes. Well
punctuated text sounds natural; a wall of clauses does not.

- One idea per sentence. Aim for an average around fifteen words.
- Front-load the point; put the caveat in its own sentence, not a nested parenthetical.
- An em dash is fine as a spoken pause. A slash is not — write "React and JavaScript", not
  "React/JS"; write "must-know versus useful context", not "must-know vs useful context".

### 5. Prefer headings and lists over tables

Screen-reader and read-aloud users navigate by heading, so keep the heading hierarchy intact
and never skip a level. A table is read cell by cell as a run-on and loses its structure out
loud — convert any table whose content is really a list into a list, and keep tables out of a
document meant to be heard. A short bulleted list under a clear heading is the layout that
serves both the eye and the ear.

### 6. Drop the decorative layer

- No emoji. It is read as its name ("brain", "check mark") or skipped, and adds nothing.
- No bare URLs. A URL is read as a mangled character string. Name the destination — "the IAB
  Tech Lab OpenRTB specification" — and let the reader search for it.
- No ASCII art, no box-drawing, no symbol shorthand for emphasis.

### 7. Carry hints in frontmatter

A YAML frontmatter block at the top of the document, fenced by lines of three dashes, gives a
reader or a read-aloud session what it needs before the first word. This is a **repo-wide
convention**: any document meant to be published as listen-to-able and read-along-able carries
it, and `format: read-aloud` is the marker a text-to-speech tool detects.

```yaml
---
format: read-aloud
kind: interview-prep          # the document type; naming only, not processing
lang: en-US
source: https://…            # provenance (optional)
generated_at: 2026-09-02T23:55:57Z   # ISO 8601, for freshness (optional)
title: "Interview Prep — Senior Software Engineer, Basis Platform and Demand-Side Platform"
pronunciation:
  Basis: "BAY sis"
  DSP: "D S P"
  OpenRTB: "open R T B"
  [redacted-name]: "shiv AWN"
sections:
  - "The setup"
  - "Domain primer"
  - "Your story"
  - "Company hooks"
  - "Likely questions"
  - "Questions to ask them"
  - "Night-before checklist"
spoken_minutes: 8
---
```

`format` / `kind` / `lang` / `source` / `generated_at` are discovery metadata for the tool;
`title` / `pronunciation` / `sections` / `spoken_minutes` are the content hints. Quote every
string value — titles and hints contain colons and dashes.

This is the portable, engine-agnostic equivalent of an SSML lexicon: a human setting up a
session reads the pronunciation map first, and an automated read-aloud step loads it directly.
The detection and delivery prompts are in
[`tts-transform-prompt.md`](tts-transform-prompt.md); the wiring is in
[`tts-integration-guide.md`](tts-integration-guide.md).

---

## Applying it here

The interview prep pack ships in **two formats, same content**:

- **Human version** (`UserJobPosting#interview_prep_pack`) is the generator's output: tables,
  written figures, standard structure. It is the default render on the job posting page.
- **Read-aloud version** (`UserJobPosting#interview_prep_pack_spoken`) is a rewrite of the
  human version by `LLM::InterviewPrepGenerator::SpokenRewriter`, following this doc, opening
  with the frontmatter block above. It is the source a downstream step turns into speech, and,
  because it is cleanly sentence-segmented, into closed captions (WebVTT or SRT) or a
  lyrics-style transcript, depending on the player.

The `interview-prep-auditor` agent checks the read-aloud version against this standard:
abbreviations spelled out, spoken-form numbers, no tables, no bare URLs, no emoji, a valid
frontmatter block. The `interview-prep` skill requires it to pass before hand-off. macOS
`say` gives a quick spot check; OpenAI and Gemini text-to-speech models sit in the synced
`Model` table but nothing wires them yet.

`docs/interview-prep/basis-dsp/reference.md` stays human-format: it is a reference doc read by
people and agents, not fed to a speech engine.

(This doc describes the standard; it is not itself a read-aloud document, so it keeps its
tables.)

---

## Sources

- [GOV.UK content design: writing for GOV.UK](https://www.gov.uk/guidance/content-design/writing-for-gov-uk) and [Use clear language](https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/clear-language/) — plain English, "to" over a dash in ranges for screen readers, short sentences (~15 words).
- [ONS content style guide: plain language](https://service-manual.ons.gov.uk/content/writing-for-users/plain-language) — short common words, sentence length.
- [Deque: Screen Readers — a guide to punctuation and symbols](https://www.deque.com/blog/dont-screen-readers-read-whats-screen-part-1-punctuation-typographic-symbols/) — inconsistent handling of symbols and punctuation across engines.
- [Adrian Roselli: Don't override screen reader pronunciation](https://adrianroselli.com/2023/04/dont-override-screen-reader-pronunciation.html) and [Ashley Sheridan: Screen readers and pronunciation](https://www.ashleysheridan.co.uk/blog/Screen+Readers+and+Pronunciation) — why `<abbr>` / pronunciation overrides are unreliable; spell out or hint instead.
- [GTFS text-to-speech guidance](https://gtfs.org/documentation/schedule/examples/text-to-speech/) — spell abbreviations fully, write large numbers as spoken, phonetic re-spelling for hard names.
- [WebAIM: Designing for screen reader compatibility](https://webaim.org/techniques/screenreader/) and [Google developer documentation style guide: write accessible documentation](https://developers.google.com/style/accessibility) — heading hierarchy without skipped levels, lists over tables.
