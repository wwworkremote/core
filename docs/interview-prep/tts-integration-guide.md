---
name: tts-integration-guide
description: >-
  How an external text-to-speech tool consumes the read-aloud interview prep
  artifacts — where the files land, the single-file model, the frontmatter
  schema for discovery and pronunciation, and the output conventions.
metadata:
  type: reference
  version: 1.0.0
---

# Text-to-speech integration guide

This is for whoever wires up the tool that turns a prep pack into audio (and,
where the player supports it, closed captions or a lyrics-style transcript).
For the transform rules themselves, hand the tool
[`tts-transform-prompt.md`](tts-transform-prompt.md); this guide is about the
files and how to find and load them.

## Where the files are

`bin/wwwr interview-prep <job_posting_id> --export[=<role>]` writes to:

```
~/ai/outbox/wwwr/interview-prep/<role>/
  pack.md          human version — not for text-to-speech
  pack.spoken.md   the text-to-speech source
```

`<role>` is the `--export=<role>` value, or the company name parameterized
(`Basis Technologies` → `basis-technologies`). One directory per role.

Your tool writes its outputs back into the same directory (see
[Output conventions](#output-conventions)).

## The single-file model

> [!IMPORTANT]
> `pack.spoken.md` is self-contained. Everything the tool needs is in that one
> file: a YAML frontmatter block, then the body. It does not need `pack.md`,
> the reference doc, or database access.

Read one file → split frontmatter from body → produce audio, captions, or a
transcript.

## Discovery — finding the files

1. **Glob**: `~/ai/outbox/wwwr/interview-prep/*/pack.spoken.md`
2. **Confirm**: the frontmatter has `format: interview-prep-read-aloud`. Skip
   anything else (a stray `pack.md` has no frontmatter).
3. **Name outputs** from the parent directory — it is the role slug.
4. **Check freshness**: `generated_at` is an ISO 8601 timestamp. Skip a file
   whose outputs you already produced with a newer `generated_at`.

A batch run globs every role directory, compares `generated_at` against
existing outputs, and processes the stale ones.

## Frontmatter schema

The block is fenced by lines of exactly three dashes. Discovery keys come
first (injected at export), then the content hints (written by the generator).

| Key | Type | Meaning | How the tool uses it |
|---|---|---|---|
| `format` | string | Always `interview-prep-read-aloud` | Discovery filter — this is a text-to-speech source |
| `lang` | BCP-47 string, e.g. `en-US` | Language and locale | Select the engine voice and locale |
| `source` | URL | The job posting this pack is for | Provenance; disambiguate two roles at one company |
| `generated_at` | ISO 8601 datetime | When the pack was produced | Freshness check against existing outputs |
| `title` | string, fully spelled out | The pack title | Speak once as the opening line; track metadata; first caption |
| `pronunciation` | map of `term` → `spoken hint` | A lexicon | Apply to every occurrence of the term — see below |
| `sections` | list of strings | The ordered section names | Chapter markers, caption chapters, navigation; each matches an `#` or `##` heading in the body |
| `spoken_minutes` | number | Estimated read-aloud length | Duration sanity check; progress indicator |

### Applying `pronunciation`

Each entry maps a word or acronym to how it should sound. Apply it everywhere
the term appears, not just the first time.

| Hint shape | Meaning | SSML |
|---|---|---|
| `DSP: D S P` | Say the letters separately | `<say-as interpret-as="characters">DSP</say-as>` |
| `OpenRTB: open R T B` | Word plus letters | `open <say-as interpret-as="characters">RTB</say-as>` |
| `Basis: BAY sis` | Respelling, capitalized syllable stressed | `<phoneme>` if you can derive one, else `<sub alias="BAY sis">Basis</sub>` |

No SSML support: substitute the hint text directly.

## The body

- Markdown headings, short bullet lists, and prose. By construction there are
  no tables, no code blocks, no emoji, and no bare URLs.
- Headings correspond to `sections`. Treat `#` and `##` as chapter cues, not
  spoken text. Speak the heading with a slight drop in pitch and rate.
- One idea per sentence — so one caption cue per sentence, one lyric line per
  sentence. Never split a sentence across cues or merge two into one.

## Output conventions

Write back into the role directory:

| File | What |
|---|---|
| `pack.mp3` (or `.wav`, `.m4a`) | The audio |
| `pack.vtt` / `pack.srt` | Closed captions, one cue per sentence |
| `pack.lrc` | Timed lyrics, one line per sentence |
| `pack.manifest.json` | Optional — what you produced, with durations, so a re-run can tell |

## Doing the transform

The rules for voice, pacing, chaptering, and the do-nots are in
[`tts-transform-prompt.md`](tts-transform-prompt.md). The authoring standard the
`pack.spoken.md` body follows is
[`tts-readable-documentation.md`](tts-readable-documentation.md).
