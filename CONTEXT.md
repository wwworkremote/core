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
