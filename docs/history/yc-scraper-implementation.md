# Implementation Archive: YC (Work at a Startup) Scraper

**Status**: [x] IMPLEMENTED (Phase 7)
**Date**: April 2026

## Context
Himalayas API is currently returning 524 (Timeout). We need a high-signal source for startups and high-quality remote roles. YC's "Work at a Startup" is the ideal target.

## Architecture

### 1. Tuning via `JobBoards::Query`
We will use the `data` column to store search parameters:
```json
{
  "type": "scraper",
  "provider": "yc",
  "filters": {
    "roles": ["Software Engineer"],
    "locations": ["Remote"],
    "min_salary": 100000,
    "equity": true
  }
}
```

### 2. Implementation: `YC::Scraper`
- **Engine**: Headless browser (Ferrum/Cuprite) recommended to handle SPA rendering.
- **Persistence**: Continues to use `JobBoards::Document` for raw HTML/JSON blobs.
- **Syncing**: Custom mapping in `JobBoards::Syncer`.

### 3. Tuning Mechanism
User can update `JobBoards::Query` records via Avo to change what the scraper "sees".

## Action Plan
1. Add `ferrum` gem.
2. Create `YC::Scraper` service.
3. Update `JobBoards::Syncer` for YC mapping.
4. Register `yc` in `DataAcquisitionManager`.
