---
name: tts-transform-prompt
description: >-
  A copy-paste instruction block for whatever tool turns a `*_spoken` file
  (the read-aloud version of an interview prep pack, or any document authored
  to docs/interview-prep/tts-readable-documentation.md) into speech, closed
  captions, or a lyrics-style transcript.
metadata:
  version: 1.0.0
---

# TTS transform prompt

The read-aloud artifacts in this system — `UserJobPosting#interview_prep_pack_spoken`, and
anything else authored to [`tts-readable-documentation.md`](tts-readable-documentation.md) —
are already written for the ear: abbreviations spelled out, acronyms expanded, numbers in
spoken form, no tables, no bare URLs, one idea per sentence, and a YAML frontmatter block up
top carrying pronunciation and structure hints.

Give the tool doing the transform **both blocks below**. They are engine-agnostic — they
apply whether the tool is an LLM orchestrating a speech engine, a thin wrapper over a
text-to-speech API, or a caption generator.

- **The detection prompt** teaches the tool to recognize an enhanced read-aloud document and
  what its frontmatter buys it.
- **The transform prompt** is the delivery rules once it is processing one.

For wiring the tool up — file discovery, the full frontmatter schema, output conventions —
see [`tts-integration-guide.md`](tts-integration-guide.md).

> [!NOTE]
> The enhanced read-aloud frontmatter (`format: read-aloud`, plus `title` / `pronunciation` /
> `sections` / `spoken_minutes`) is a **repo-wide convention**, not specific to interview
> prep. Any document meant to be published as listen-to-able and read-along-able carries it
> and follows [`tts-readable-documentation.md`](tts-readable-documentation.md).

---

## The detection prompt

> **Detecting an enhanced read-aloud document**
>
> Before processing any Markdown file, check whether it is an **enhanced read-aloud document**
> — one already written for speech and carrying a metadata block for you.
>
> **It is enhanced if** the file opens with a YAML frontmatter block (the first line is `---`,
> closed by a later line that is exactly `---`) and that block contains **`format: read-aloud`**.
> A `kind:` key (for example `kind: interview-prep`) names the document type but does not
> change how you process it. As a looser fallback, treat it as enhanced if the block contains
> `pronunciation:`, `sections:`, and `spoken_minutes:` together.
>
> **If there is no such block**, treat the file as a plain document: best-effort
> text-to-speech, derive a title from the first heading, chapter on `#` / `##`, no lexicon.
>
> **When the block is present, read it for context — never speak it — and use it to publish
> two paired artifacts:**
>
> | Key | Use it for |
> |---|---|
> | `kind` (optional) | The document type (e.g. `interview-prep`) — for naming and grouping the published artifacts, not for processing |
> | `title` | The published title of the audio track, the caption file, and the transcript header |
> | `lang` (e.g. `en-US`) | Voice and locale selection |
> | `pronunciation` (map of term → spoken hint) | A lexicon: apply to **every** occurrence of each term in the audio (as `<say-as>` / `<phoneme>` / `<sub>` or plain substitution). Leave the written spelling untouched in captions and transcript. |
> | `sections` (ordered list) | Chapter markers in the audio; chapter cues in the captions; the heading list in the read-along transcript. Each entry matches an `#` / `##` heading in the body. |
> | `spoken_minutes` (number) | Expected duration — put it in the published metadata; sanity-check your output against it; do not pad or rush to hit it. |
> | `source` (URL) | Provenance for the published artifact's metadata |
> | `generated_at` (ISO 8601) | Freshness — skip a file you have already published from at this timestamp or newer |
>
> **Produce, for publication:**
>
> 1. **Listen-to-able** — an audio file with the `pronunciation` lexicon applied, chaptered by
>    `sections`, spoken in a neutral, measured, informational voice at a moderate pace.
>    Punctuation drives the pauses.
> 2. **Read-along-able** — time-synced captions (WebVTT) and a plain transcript, **one cue and
>    one line per sentence**, aligned to the audio and chaptered by `sections`, so a reader can
>    follow the text while the audio plays.
>
> The body is already speech-ready: abbreviations spelled out, acronyms expanded, numbers in
> spoken form, no tables, no bare URLs, one idea per sentence. **Do not re-expand, rewrite,
> summarize, reorder, or drop anything.** Markdown headings and bullets are structure, not
> speech.
>
> If the frontmatter is partial or malformed, use whatever parses and fall back to the
> plain-document defaults for the rest.

---

## The transform prompt

> You are converting a **read-aloud document** into audio (and, if the target player needs
> it, into closed captions or a lyrics-style transcript). The document is already optimized
> for speech — **do not rewrite, re-expand, or "improve" the wording**. Your job is delivery,
> not editing.
>
> ### 1. Parse the frontmatter, never speak it
>
> The document opens with a YAML block fenced by lines of three dashes. Read it for
> instructions, then drop it — none of it is spoken.
>
> - **`title`** — the utterance or track title. Speak it once as the opening line, then a
>   full pause, before the first section. If the target is captions, it is the first cue or
>   the track metadata, not a spoken line.
> - **`pronunciation`** — a lexicon. Each entry maps a word or acronym to how it should sound:
>   - `"DSP: D S P"` — say the letters separately, with a short gap between them. Apply as
>     SSML `<say-as interpret-as="characters">` or spell-out.
>   - `"Basis: BAY-sis"` — a respelling; the capitalized syllable takes the stress. Apply as
>     SSML `<phoneme>` if you can derive one, otherwise `<sub alias="BAY sis">`.
>   Apply every entry everywhere the term appears, not just the first time.
> - **`sections`** — the ordered section list. Each is a chapter boundary: insert a chapter
>   marker (or a caption chapter cue), and speak the heading with a slight drop in pitch and
>   rate and a pause before and after. Do not shout headings.
> - **`spoken_minutes`** — the author's duration estimate. Use it as a sanity check on total
>   output length and for a progress indicator; do not pad or rush to hit it.
>
> ### 2. Speak the body
>
> - **Voice**: neutral, measured, informational. This is a briefing, not an advertisement.
>   Moderate pace — the content is dense, so err slower rather than faster.
> - **Punctuation is the score.** Pause on commas, longer on periods and dashes, longer still
>   between paragraphs. Do not add pauses the punctuation does not call for.
> - **Markdown is structure, not speech.** Never voice `#`, `*`, `-`, `>`, backticks, or list
>   bullets. A heading is a chapter cue (above). A list item is a sentence with a short
>   trailing pause. A block quote is spoken plainly.
> - **Do not spell things out again.** The text already says "Senior", "for example", "under
>   one hundred milliseconds". Read it as written.
> - **Emphasis**: honor `**bold**` as light stress on that phrase. Ignore italics unless the
>   sentence clearly needs the lift.
>
> ### 3. If the target is closed captions (WebVTT or SRT)
>
> - **One cue per sentence.** The source is written one idea per sentence for exactly this.
>   Never split a sentence across cues; never merge two sentences into one cue.
> - Cue length **one to seven seconds**, roughly 1 to 2 lines of about 40 characters. If a
>   sentence runs longer, break the cue at a comma or a natural clause boundary, not
>   mid-phrase.
> - Section headings get their own short cue, optionally styled as a chapter title.
> - Align the final cue's end time to the audio's true end; use `spoken_minutes` only to
>   check you are in the right range.
>
> ### 4. If the target is a lyrics-style transcript (LRC or plain)
>
> - **One line per sentence.** Headings are their own line, blank line before and after.
> - For timed LRC, timestamp each line at the start of its spoken audio.
> - No markdown, no frontmatter, no cue numbers — just the spoken lines.
>
> ### 5. Do not
>
> - Do not read the frontmatter, its keys, or its fence.
> - Do not read URLs (there should be none; if you find one, say "link in the notes" and move
>   on).
> - Do not invent SSML the author did not imply — pronunciation entries and
>   punctuation-driven pauses are the whole budget.
> - Do not change section order, drop a section, or summarize.

---

## Applying pronunciation entries

| Frontmatter entry | Meaning | SSML |
|---|---|---|
| `DSP: D S P` | say each letter, short gaps | `<say-as interpret-as="characters">DSP</say-as>` |
| `OpenRTB: open R T B` | mixed word + letters | `open <say-as interpret-as="characters">RTB</say-as>` |
| `Basis: BAY-sis` | respelling, stress on caps | `<phoneme alphabet="ipa" ph="ˈbeɪ.sɪs">Basis</phoneme>` or `<sub alias="BAY sis">Basis</sub>` |
| `[redacted-name]: shiv-AWN` | respelling, stress on middle | `<sub alias="shiv AWN">[redacted-name]</sub>` |

If the engine has no SSML, fall back to substituting the spoken hint text directly.
