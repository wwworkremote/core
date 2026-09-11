# ADR: Audit Strategy - PaperTrail vs Rails Event Store

## Context
Project needs record versioning and auditing, specifically for AI-generated categorization and metadata updates. Rails Event Store (RES) was previously integrated for high-volume ingestion event streams.

## Decision
Remove Rails Event Store (RES) and utilize **PaperTrail** for record auditing.

## Rationale
1. **Complexity**: RES requires defining explicit event classes and handlers. For simple field-level auditing (e.g. `ai_category` changes), PaperTrail provides a "set and forget" integration.
2. **Current Needs**: API volume has decreased. The event-driven architecture of RES is currently overkill for the existing data flow.
3. **Maturity**: PaperTrail is the industry standard for ActiveRecord versioning.
4. **Scraper Strategy**: New ingestion volume will come from web scrapers tuned via `JobBoards::Query`. This logic is state-driven (polling/scraping) rather than event-driven.

## Consequences
- `rails_event_store` gem removed from Gemfile.
- `/res` route removed from `config/routes.rb`.
- `JobPosting` model now tracks versions automatically via `has_paper_trail`.
- Audit logs for AI categorization are now accessible via `JobPosting.last.versions`.
