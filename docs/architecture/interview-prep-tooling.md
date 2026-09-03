---
name: interview-prep-tooling
description: >-
  How the interview prep pack tooling fits together — generation, the
  read-aloud rewrite, storage, the job-posting surface, the outbox export,
  and the audit/grounding loop the skill runs.
metadata:
  type: architecture
  version: 1.0.0
---

# Interview prep tooling

The **interview prep pack** is a bespoke briefing per `(candidate, posting)`: role setup,
domain primer, story arc, company hooks, referral play, likely questions, questions to ask,
night-before checklist. It ships in two versions with identical content — a **human** version
and a **read-aloud** version for text-to-speech.

## Surfaces

| Surface | Entry point |
|---|---|
| Job posting page | "Generate Prep Pack" button → `generate_interview_prep` action; renders the pack and a "Read-aloud version" toggle |
| CLI | `bin/wwwr interview-prep <id> [--regenerate] [--spoken] [--export[=<role>]]` (`bin/wwwr help interview-prep`) |
| Skill | `interview-prep` — generate, then audit and ground before hand-off |
| Agent | `interview-prep-auditor` — read-only diff against the quality bar |
| Export | `~/ai/outbox/wwwr/interview-prep/<role>/pack.md` + `pack.spoken.md` |

## Generation and read-aloud rewrite

```mermaid
sequenceDiagram
    autonumber
    actor Op as Operator / skill
    participant CLI as bin/wwwr interview-prep
    participant Gen as LLM::InterviewPrepGenerator
    participant PB as PromptBuilder
    participant Orc as LLM::Orchestrator
    participant Guard as Guardrails::Pipeline
    participant Model as Model (local, or defaults.interview_prep)
    participant SR as SpokenRewriter
    participant UJP as UserJobPosting

    Op->>CLI: interview-prep <id> --regenerate
    CLI->>Gen: call(user, job_posting, force: true)
    Gen->>PB: assemble prompt
    Note over PB: CareerProfile history · JobPosting body ·<br/>stored Company audit · linked Contact ·<br/>standing criteria · PipelinePrompt override
    PB-->>Gen: prompt
    Gen->>Orc: call(untrusted_text: prompt, ...)
    Orc->>Guard: screen the posting text
    Guard-->>Orc: sanitized
    Orc->>Model: complete
    Model-->>Orc: human pack (markdown)
    Orc-->>Gen: output
    Gen->>UJP: update!(interview_prep_pack: ...)
    Gen->>SR: call(human_pack)
    SR->>Orc: call(untrusted_text: human_pack, read-aloud rules)
    Orc->>Model: complete
    Model-->>Orc: read-aloud pack (frontmatter + body)
    Orc-->>SR: output
    SR-->>SR: unwrap_fence
    SR-->>Gen: read-aloud pack
    Gen->>UJP: update!(interview_prep_pack_spoken: ...)
```

> [!NOTE]
> The read-aloud version is a **rewrite of the human version**, not an independent
> generation, so the two carry identical content. A failed rewrite is non-fatal — the human
> pack still lands and `interview_prep_pack_spoken` stays null.

## The pack lifecycle

```mermaid
flowchart TD
    Gen[Generate] --> Human[interview_prep_pack<br/>human version]
    Human --> SR[SpokenRewriter]
    SR --> Spoken[interview_prep_pack_spoken<br/>read-aloud version]

    Human --> Page[Job posting page<br/>markdown render + edit form]
    Spoken --> Page

    Human -->|bin/wwwr --export| PackMd["~/ai/outbox/wwwr/interview-prep/&lt;role&gt;/pack.md"]
    Spoken -->|bin/wwwr --export| PackSpoken["pack.spoken.md<br/>+ discovery frontmatter"]

    PackSpoken --> TTS[External text-to-speech tool<br/>docs/interview-prep/tts-transform-prompt.md]
    TTS --> Audio[pack.mp3]
    TTS --> Captions[pack.vtt / pack.srt]
    TTS --> Transcript[pack.lrc / transcript]
```

On `--export` the read-aloud frontmatter is re-serialized: discovery keys first
(`format: read-aloud`, `kind`, `lang`, `source`, `generated_at`) so a directory scan can
identify and load the file, then the model's content hints (`title`, `pronunciation`,
`sections`, `spoken_minutes`). The re-serialization also repairs a malformed model block into
valid YAML.

## The skill's audit and grounding loop

```mermaid
flowchart LR
    Start([interview scheduled]) --> G[Generate the pack]
    G --> A[interview-prep-auditor<br/>diff vs quality bar]
    G --> I[industry-intelligence-agent<br/>verify primer concepts,<br/>acronym citations, links]
    A --> Fold[Fold mechanical fixes<br/>+ grounding corrections]
    I --> Fold
    Fold --> P{Pressure-test?}
    P -->|optional| PT[career-coach-agent ·<br/>hiring-manager-agent ·<br/>recruiter-agent]
    P -->|no| Hand
    PT --> Hand[Hand off: sharpened pack<br/>+ judgement calls]
```

The quality bar is `docs/interview-prep/_reference/reference.md` (a hand-written,
fully synthetic worked example). The local model's structure is reliable; its
content is a scaffold — see the skill's "known failure modes" section.

## Key components

| Component | Role |
|---|---|
| `LLM::InterviewPrepGenerator` | Orchestrates generation + the read-aloud rewrite; stores both on `UserJobPosting` |
| `LLM::InterviewPrepGenerator::PromptBuilder` | Assembles the human-pack prompt; `PipelinePrompt` key `interview_prep_pack` |
| `LLM::InterviewPrepGenerator::SpokenRewriter` | Rewrites the human pack for text-to-speech per `docs/interview-prep/tts-readable-documentation.md` |
| `UserJobPosting#spoken_pack_parts` | Splits the read-aloud frontmatter from the body |
| `Wwwr::InterviewPrep` | CLI logic: print / regenerate / `--spoken` / `--export` |
| `UserJobPostingsController#generate_interview_prep` | The page button; shares `#run_llm` with match + cover-letter |

## Related docs

- `docs/interview-prep/README.md` — the feature docs index
- `docs/interview-prep/tts-readable-documentation.md` — the read-aloud authoring standard
- `docs/interview-prep/tts-transform-prompt.md` — detection + delivery prompt for the TTS tool
- `docs/interview-prep/tts-integration-guide.md` — wiring the TTS tool
- `TASK-145` — `LLM::Orchestrator` is broken on the Gemini provider; blocks a stronger model on this path
