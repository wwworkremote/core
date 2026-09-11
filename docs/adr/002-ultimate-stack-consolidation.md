# ADR 002: Ultimate Stack Consolidation

## Context
Following the "Gemfile of Dreams" audit, we identified that the current infrastructure is overly complex for a single-user, local-first tool. Specifically, maintaining Redis for Sidekiq, Devise for authentication, and various external dependencies adds operational overhead without proportional value.

## Decision
1.  **Shift to "Solid" Stack:** Officially adopt `solid_queue`, `solid_cache`, and `solid_cable` as the primary infrastructure components. This allows us to remove Redis entirely and rely solely on PostgreSQL.
2.  **Simplify Authentication:** Remove Devise. Given this is a personal tool, we will use a simple `User` model with `has_secure_password` and HTTP Basic Authentication for dashboard access.
3.  **Lightweight APIs:** Reject complex serialization frameworks (Alba/GraphQL) in favor of standard Rails JSON patterns for internal use.
4.  **Proactive Guardrails:** Introduce `strong_migrations`, `database_consistency`, and `isolator` to prevent common architectural pitfalls.

## Consequences
- **Positive:**
    - Reduced memory footprint (no Redis container).
    - Simplified deployments and local setup.
    - Faster build times and fewer dependencies.
    - Improved data integrity via transaction safety tools.
- **Negative:**
    - Manual migration of authentication logic.
    - Slight increase in PostgreSQL connection usage (due to Solid Queue).
