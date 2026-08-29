# Core Context: wwworkremote

## Domain Language
- **Job Posting:** A single job opening captured from an external source.
- **Career Profile:** User's overarching career data, goals, and legacy resume text.
- **Resume:** A specific, versioned instance of a resume track (e.g., "Backend" vs "Engineering Manager").
- **Job Search:** A campaign grouping applications using a specific Resume version.
- **Skill:** A centralized master list of technical and soft skills with vector embeddings.
- **Pump Track:** The recurring four-phase loop of Intake, Resolution, Response Construction, and Reorientation that describes one lap of the job-search game.
- **Guided Session:** A supervised lap in which the system records what happened and why, while Mike retains authority at ambiguous or irreversible transitions.
- **Session Purpose:** The declared intent for a Guided Session: application research observes and records an employer flow without commitment, while application execution works toward applying under supervision.
- **Question Occurrence:** One question as observed in one application context, retaining its exact wording and links to the application, posting, company, industry, provider, persona, and outcome.
- **Question Archetype:** A reviewable concept that groups semantically equivalent Question Occurrences without erasing their wording or provenance; archetypes may be merged, split, or corrected as evidence improves.
- **Answer Strategy:** A provenance-bearing approach for responding to a Question Archetype, ranging from deterministic profile facts and authored templates to persona-aware synthesis requiring richer evidence.
- **Answer Sophistication:** The degree of reasoning and contextual tailoring an Answer Strategy requires; frequency alone does not make an answer safe to reuse verbatim.
- **Reference Scenario:** The one stored `Scenario` per provider whose ordered signatures and structure are the current best understanding of a correct end-to-end flow. Promotion is always manual, after Mike reviews the diff.
- **Reference Comparison:** The act of diffing one guided session (materialized into a normal `Scenario`) against its provider's Reference Scenario. Compares signature kinds, field structure, screening-question occurrences and archetypes, step and phase order, and commitment boundaries reached.
- **Signature Namespace:** The controlled vocabulary that classifies a captured signature: `field`, `screening_question`, `step`, `commitment_boundary`, or `ats_identity` for a bare provider id. An unrecognized namespace is `unknown_namespace` — surfaced with a diagnostic and excluded from structural conclusions, never silently treated as a provider id.
- **Reached Scope:** The portion of a Reference Scenario's process a guided session actually reached, bounded by its Session Purpose and by where it stopped at a Commitment Boundary. Comparison is overlap-aware: it only claims drift within Reached Scope.
- **Coverage:** How much of the applicable reference process a session reached — reference checkpoints reached over reference checkpoints applicable to the session's purpose. An `application_research` session stopping before submission is incomplete coverage by design, not a malfunction. Kept visible as a phase/step map, not only a percentage.
- **Drift:** A difference between what a session observed and the Reference Scenario, measured only within Reached Scope. Distinct from a Coverage gap, which is the reference having steps the session never reached.
- **Finding:** A persistent, reviewable record of one thing a Reference Comparison inferred — a single drift or coverage gap. Distinct from a Guided Session Event (what happened) and a Disposition (what Mike decided).
- **Disposition:** Mike's recorded resolution of a Finding, one of: provider/site drift, reference incomplete or stale, expected persona variation, expected session-purpose variation, or unresolved (needs investigation). Never discards the underlying observation — persona and purpose variation are preserved as evidence even when they raise no operational alert. Dispositions are append-only: the latest *applicable* judgment wins for presentation, but every prior disposition stays a first-class record and is never overwritten. A carried-forward disposition from an earlier comparison run is only ever a suggested default; the new Finding starts undispositioned.

## Core Concepts
- **Vector Search:** Using pgvector to find similarities between Resume versions and Job Postings.
- **Lineage:** Resumes can be "forked" from parents, creating a linear version history per track.
- **Multi-format:** Resumes are stored as JSONB to facilitate export to PDF, Markdown, JSON, and MCP.

## Operational Mandates ("What Matters")
- **Asymmetric Sync Rule:** Use soft deletes (`discarded_at`) for user-managed data to prevent "record resurrection" during external API syncs.
- **Solid Stack Safety:** SolidQueue/Cache/Cable must use explicit `connects_to` write connections.
- **zdots Rule (Account Separation):** Strict isolation of `_ro` (Read-only), `_w` (Write-only), and `_rw` (Read-write) database accounts to prevent drift.
- **Intent Is First-Class:** Capturing an action is not enough; the system must preserve the actor's intent, available alternatives, state changes, reversibility, and approval requirements.
- **Bounded Agency:** Automation may handle deterministic, reversible work, but Mike remains the approving actor for ambiguity and irreversible actions such as final application submission.
- **Commitment Boundary:** The point where a provider action transmits sensitive data, creates consequential persistent state, accepts terms, or submits an application. Crossing it is distinct from opening and researching an application flow and requires explicit approval.
