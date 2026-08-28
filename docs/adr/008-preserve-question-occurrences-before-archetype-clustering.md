# ADR 008: Preserve Question Occurrences Before Archetype Clustering

## Status
Accepted

Every application question is first preserved as an immutable, contextual
Question Occurrence linked to the application, posting, company, industry,
provider, persona, and outcome. Semantically similar occurrences may then be
grouped under a reviewable Question Archetype, while reusable Answer Strategies
attach to the archetype rather than replacing occurrence history. This keeps
frequency analysis and answer reuse possible without flattening subtly
different questions into one mutable canned-answer row.

## Consequences

- Exact wording and per-application provenance survive archetype corrections.
- Archetype assignment is reviewable and supports merge and split operations.
- Answers retain source, persona, version, confidence, and outcome evidence.
- Common questions may use deterministic or authored answers, but frequency
  alone never authorizes reuse, form filling, or submission.
