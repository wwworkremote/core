# One Posting's Journey Through the Pipeline

A single sequence, start to finish: a posting is discovered, Mike triages it, applies through the
extension, and eventually hears back. Not every posting reaches every step — most stop at triage.

```mermaid
sequenceDiagram
    actor Mike
    participant Board as Job board / email
    participant Ingest as Ingestion pipeline
    participant JP as JobPosting
    participant Triage as Triage queue
    participant UJP as UserJobPosting
    participant Ext as Chrome extension
    participant Session as GuidedSession timeline
    participant Comp as Company

    Board->>Ingest: raw listing
    Ingest->>JP: create (status: none)
    Note over JP: Categorized, embedded,<br/>geo-filtered

    Mike->>Triage: reviews queue
    alt Skip
        Triage-->>Mike: next posting
    else Favorite
        Triage->>JP: favorite! (status)
        Triage->>UJP: advance_pipeline_state!("favorite")
        Note over JP,UJP: Same click, two models kept<br/>in sync (TASK-82 phase 1)
    else Not interested / Expired
        Triage->>JP: ignore! / expire!
        Note over UJP: No pipeline event logged --<br/>these are posting-lifecycle facts
    end

    Mike->>Ext: opens the ATS application page
    Mike->>Session: starts supervised pump-track lap
    Session-->>Mike: current phase + next proposed move
    Ext->>Ext: content.js extracts fields
    Ext->>Session: record meaningful transition + intent
    Mike->>Ext: submits application
    Note over Session: Final submission is an explicit<br/>approval-gated User Task
    Ext->>UJP: record_status_event!("apply")
    UJP->>UJP: PipelineStep logged
    Session->>Session: retain evidence, classification, and decision

    alt Interview scheduled
        Mike->>UJP: mark interviewing
    end

    alt Employer responds
        alt Rejected
            Mike->>UJP: outcome = rejected (+ reason, email — TASK-91)
            UJP->>Comp: last_denied_on = today (TASK-91.2)
            Note over Comp: Cooldown starts --<br/>postings here suppressed ~6mo
        else Offered
            Mike->>UJP: offer! (current model --<br/>see open question in statechart doc)
        end
    else No response
        Note over UJP: No PipelineStep in 2-3 days
        UJP-->>Mike: idle notification (TASK-93, not yet built)
    end
```

## Reading this against the real code

- Triage's Favorite/Not interested/Expired all post to `Admin::PipelineStepsController`
  (`app/controllers/admin/pipeline_steps_controller.rb`) — one controller, one endpoint, dispatching
  on `params[:status]`.
- The extension's apply event lands via `Api::V0::ApplicationStatusesController`, which calls
  `UserJobPosting#record_status_event!` directly — the extension never touches `JobPosting.status`.
- The idle-notification and company-cooldown steps are drawn here because they're the *intended*
  next links in this chain, not because they exist yet — see TASK-93 and TASK-91.2.
