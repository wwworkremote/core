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
