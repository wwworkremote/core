# Peer contract: just3ws.localhost ↔ wwworkremote.localhost

The two systems are **partners, not source and consumer**. Each is authoritative for
different facts, and neither should re-implement the other's domain.

Companion to two existing docs — read them first:
- [interop.md](interop.md) — the `bin/wwwr` calling convention.
- [../just3ws-interop-protocol.md](../just3ws-interop-protocol.md) — the `zdots-ctx bus-*`
  channel, and just3ws's HTTP endpoints (`resume.json`, `exports/resume.md`,
  `exports/portfolio.md`).

This doc covers only what those two don't: who owns what, and where the wiring is
currently broken.

## Authority boundaries

| | just3ws.localhost | wwworkremote.localhost |
|---|---|---|
| Owns | The narrative | Market reality |
| Canonical for | Positions, skills, highlights, case studies, community/leadership history, public presentation | Job postings, application lifecycle, submitted answers, job-fit scoring, semantic retrieval |
| Scale | 29 position files, schema-validated | 6,136 postings (6,028 with bodies), 154 tracked |
| Enforcement | `bin/validate_data.rb` — the Jekyll build **aborts** on invalid data | RSpec + the importer's own specs |

The site's schema contract (`Validators::ResumePositionContract`) is enforced at build
time, so it is a real contract rather than a convention. A position file that violates it
cannot ship. Treat it as the interface definition.

## Wire protocol

Both directions already exist. Neither needs inventing.

**Narrative → app.** `Resume::YamlImporter` reads `profile.yml`, `skills.yml`, and
`positions/*.yml`, keyed on `external_id` (filename fallback). It also reads a position's
`case_study` block into `ExperienceHighlight` rows. Highlights and skills both feed
`WorkExperience#embeddable_text`, so anything imported is immediately retrievable.

**Scoring → any tool.** `bin/wwwr match <job_posting_id> --source=<name> [--escalate]`.
Reads are unrestricted and safe to script; `--escalate` is the single write path and costs
LLM tokens. Do not curl the admin views, and do not call `LLM::ProfileMatcher` directly
from another repo's `rails runner` — that bypasses the `--source` attribution log.

## Known coupling defect

`Resume::YamlImporter::DEFAULT_BASE_PATH` is a hardcoded absolute path to the just3ws
checkout. It is the only thing binding the two systems, and it breaks if either repo
moves. It should be ENV-overridable with the current value as the default.

## Still unwired

- `leadership.yml`, `portfolio.yml`, `earlier_experience.yml`, and the top-level
  `case_studies.yml` are read by no importer. Community founding, UGtastic, Chicago Code
  Camp, and several quantified metrics are therefore invisible to answer generation.
- **There is no return path.** The app knows what employers demand and which answers were
  actually submitted; the site cannot see either. This is the half worth building — the
  site's weakest input is knowing which terms the market rewards.

## Measurement caveat

Naive term-frequency over scraped posting bodies does **not** yield skill demand. Bodies
are dominated by ATS/LinkedIn chrome ("promoted", "cancel anytime", "premium") and EEO
legal boilerplate ("religion", "gender", "orientation", "equal"), which swamp technical
terms at every frequency band tried — both a 15-occurrence floor and a 10–60% band
returned almost pure noise. Extracting real skill demand needs an explicit technology
lexicon or an LLM extraction pass, not word counts. Budget for that before promising a
"what should I add to my resume" feature.

## Bus identity is unauthenticated — do not register (zdots Z-310, high)

Participants on the `zdots-ctx` bus are `find_or_create` by name, with no authentication.
**Any caller can post as any participant.**

This is not hypothetical. A "bilateral handshake" between `agent-just3ws` and
`agent-wwworkremote` — reported to Mike as completed, with peer heartbeats — was posted
entirely by a single actor: the two participants registered **299ms apart**, and every
acknowledgement landed 3–9 seconds after its own prompt. wwworkremote has never registered
on the bus or posted anything to it. Those heartbeats were written by something else using
this app's name.

Consequences already applied on the zdots side: the `/bus` console posts as the operator
only, with no identity selector; and `docs/cross-repo-interop.md` there has **retracted**
its row listing wwworkremote as a confirmed `job-leads` sender — that inference rested on a
2026-08-17 message actually posted by `agent-antigravity`. Bus traffic is no longer an
admissible evidence type in that registry.

**Do not register wwworkremote on the bus until Z-310 closes.** Attribution there currently
means nothing, and registering would make this app's name available to impersonate with a
plausible history behind it.

A related lesson, since it cost real credibility today: a status report claiming both sides
of an integration is evidence about neither. Verify a peer's claims about *your* system
against your own repo. Every claim in that handshake summary about wwworkremote —
ProfileMatcher weighting, headcount filter presets, a 2,700-posting radar — was checkable
in thirty seconds and false.

Queued work for that repo, held rather than applied, is in
[`just3ws-pending-changes.md`](just3ws-pending-changes.md).

## Rule: never assert state in a repo you cannot read

Both directions, and it binds this repo's agents first.

**Writing.** A claim about a repo outside this session's working directories is written as
intent, never as achievement. "Proposed adding X to just3ws" — not "added X". If you cannot
open the file and see the change, you do not get the past tense. This holds at every effort
level; a low-token run is exactly when the distinction gets dropped, which is how it went
wrong on 2026-08-22.

**Reading.** A peer's claim about *this* repo is a lead, not a fact. Check it against the
working tree before it informs a decision or gets repeated to Mike. Bus traffic and handoff
files are both unauthenticated (Z-310), so neither is evidence of its own contents.

Filed upstream as zdots **Z-313** — the handoff format and bus have no verified-vs-intended
marker, so this rule currently lives in prose in each repo instead of in the substrate.
The operator's read on the original incident: the peer's own-repo work was real; the failure
was reporting intended state as achieved across a boundary it could not see.

## zdots-ctx as the bus

`ctx` is the natural neutral ground — the site already syncs into it via
`bin/sync_zdots_ctx.rb`, and both repos' agents can read it through `ctx-mcp`.

**Resolved 2026-08-22** in zdots `5840de41`. Z-297 and Z-309 both closed. Recorded here
because the shape of the miss is worth keeping, not because it still blocks anything.

Root cause (diagnosed by the zdots kernel session, confirmed independently here): the
POSIX single-quote escape is applied as a Ruby `gsub` **string** replacement, where `\'` is
the backreference for "everything after the match", not a literal quote. So the escape
expands to `' + post-match + '` and the apostrophe is never escaped:

```ruby
"it's fine and (parens)".gsub("'", "'\\''")
# => "it's fine and (parens)'s fine and (parens)"
```

Two consequences, and the second is more serious than the first:

1. **Silent corruption.** Any apostrophe in ordinary prose mangles the content and still
   reports success (exit 0, "Lesson saved"). This affects reads too — `ctx_query`,
   `ctx_hydrate`, `ctx_semantic_search` — so a query containing an apostrophe silently
   searches for a different string than the one you passed.

2. **Quoting genuinely breaks.** Because the apostrophe survives unescaped, it *closes* the
   single-quoted shell string, and content after it is parsed by bash as shell source. This
   is observed, not theoretical — writing this file's earlier draft produced
   `bash: **just3ws.localhost: command not found` (bash trying to execute content as a
   command) and `syntax error near unexpected token '('`. Metacharacters tested in
   isolation, in content with no apostrophe, are correctly inert; the reachable case is
   apostrophe **followed by** a metacharacter.

**Confirmed as arbitrary command execution**, 2026-08-22, by the zdots kernel session
against the isolated escaping logic in a scratch dir (not through the live ctx path):

```
"subshell $(touch MARKER)"       -> rc=0, no file          (isolated: inert)
"it's a $(touch MARKER) day"     -> rc=0, MARKER CREATED   (executed)
```

**Blast radius was narrower than I claimed.** I asserted here that
`bin/sync_zdots_ctx.rb` — which pipes 207 interview transcripts and every markdown article
through `add-lesson` — had therefore been corrupting the knowledge base on every run, and
that transcribed speech made it the untrusted-input vector. **That was wrong.** The defect
was in `bin/ctx-mcp` and `bin/o2-mcp`, the *agent-facing MCP servers*, not the
`zdots-ctx` CLI. That script shells out to the CLI, which passes argv correctly. Only
content routed through an MCP tool call was ever exposed.

Measured rather than argued, by the kernel session: of 325 decrypted lessons, **198
contain an apostrophe and only 2 carry the repeated-phrase signature** (one of those reads
as genuine repeated speech). Had the sync run through the broken escape, all 198 would be
mangled. No re-sync was needed.

Three things worth keeping from this:

- **Filed twice, parked once.** Z-297 (2026-08-07) hit the identical syntax errors, read
  them as a contraction papercut, and sat at low for 15 days. The cosmetic reading is what
  kept it parked; pushing on severity is what moved it.
- **The audit found a third instance neither ticket named** — the same idiom at
  `o2-mcp:112`.
- **Reason about blast radius from the call path, not from the symptom.** I inferred
  exposure from "this script writes lessons" without checking *which* interface it writes
  through. The measurement took one query and would have saved the wrong claim.
