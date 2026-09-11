# System Components and How They Collaborate

The high-level shape: external job sources feed an ingestion pipeline that produces `JobPosting`
records; Mike works those postings through the Rails app and the Chrome extension; every action
on either side lands in the same `PipelineStep` audit trail.

```mermaid
flowchart TB
    subgraph Sources["External sources"]
        Boards["Job boards\n(LinkedIn, Indeed, Greenhouse,\nWorkday, ADP, direct-hiring pages)"]
        Email["Forwarded emails\n(EmailImporter)"]
    end

    subgraph Ingestion["Ingestion (packages/ingestion)"]
        Fetchers["Source Fetcher adapters\n(one per board family)"]
        Syncer["Syncer / Normalizer"]
        Categorizer["LLM Categorizer + Embedder"]
    end

    subgraph Core["Core Rails app"]
        JobPosting[("JobPosting\nlifecycle: none/ignored/purged/expired")]
        Company[("Company\ndisposition, cooldown")]
        UserJobPosting[("UserJobPosting\nstage + outcome, per user")]
        PipelineStep[("PipelineStep\nshared audit log")]
        AdminUI["Admin UI\n(triage queue, job posting show,\ndashboard)"]
        API["api/v0 controllers"]
    end

    subgraph ExtensionBox["Chrome Extension"]
        Content["content.js\n(page overlay, field extraction)"]
        Background["background.js\n(service worker, message relay)"]
        Sidepanel["sidepanel.js\n(application cockpit)"]
    end

    CLI["bin/wwwr CLI"]

    Boards --> Fetchers
    Email --> Fetchers
    Fetchers --> Syncer --> Categorizer --> JobPosting
    JobPosting --> Company

    AdminUI -->|triage decisions,\npipeline pills| JobPosting
    AdminUI -->|favorite/apply/interview/\noffer/archive, outcome| UserJobPosting
    UserJobPosting -->|record_status_event!| PipelineStep
    JobPosting -->|pipeline_steps.create!| PipelineStep

    Content -->|scrapes ATS page| Background --> Sidepanel
    Sidepanel -->|application field answers,\nstatus events| API --> UserJobPosting

    CLI -->|bin/wwwr transition| JobPosting
    CLI -->|dual-write, TASK-82| UserJobPosting
```

## What each piece owns

| Component | Owns | Does not own |
|---|---|---|
| `JobPosting` | Whether the listing itself is alive (`none`/`ignored`/`purged`/`expired`) | Whether Mike is pursuing it |
| `Company` | Reputation signals, ingestion toggles, decline cooldown (TASK-91) | Any single posting's state |
| `UserJobPosting` | Mike's pipeline stage and the employer's outcome for one posting | The posting's own lifecycle |
| `PipelineStep` | The append-only audit trail — every status change and note, from any writer | Current state (it's a log, not a projection) |
| Chrome extension | Reading the ATS page Mike is actually looking at, and writing that context back | Anything about postings Mike hasn't opened |
| `bin/wwwr` | A terminal-native path to the same actions the UI takes | A separate data model — see the pipeline statechart doc |

See `pipeline-statechart.md` for how `JobPosting`, `UserJobPosting`, and outcome actually transition,
and `application-sequence.md` for the same system shown as a single request's journey through it.
