# Core Context: wwworkremote

## Domain Language
- **Job Posting:** A single job opening captured from an external source.
- **Career Profile:** User's overarching career data, goals, and legacy resume text.
- **Resume:** A specific, versioned instance of a resume track (e.g., "Backend" vs "Engineering Manager").
- **Job Search:** A campaign grouping applications using a specific Resume version.
- **Skill:** A centralized master list of technical and soft skills with vector embeddings.

## Core Concepts
- **Vector Search:** Using pgvector to find similarities between Resume versions and Job Postings.
- **Lineage:** Resumes can be "forked" from parents, creating a linear version history per track.
- **Multi-format:** Resumes are stored as JSONB to facilitate export to PDF, Markdown, JSON, and MCP.

## Operational Mandates ("What Matters")
- **Asymmetric Sync Rule:** Use soft deletes (`discarded_at`) for user-managed data to prevent "record resurrection" during external API syncs.
- **Solid Stack Safety:** SolidQueue/Cache/Cable must use explicit `connects_to` write connections.
- **zdots Rule (Account Separation):** Strict isolation of `_ro` (Read-only), `_w` (Write-only), and `_rw` (Read-write) database accounts to prevent drift.

