# Contributing to WWWorkRemote

We welcome contributions that improve the accuracy, performance, or intelligence of the job synthesis engine.

## 🛡️ Engineering Mandates

### 1. Database Safety & Environmental Context
**CRITICAL**: The development database contains high-fidelity data and MUST NEVER be reset or modified by test suites.

- **Mandatory Prefix**: ALL shell commands that interact with the Rails stack MUST use an explicit `RAILS_ENV` prefix (e.g., `RAILS_ENV=test bundle exec rspec`).
- **Standard Wrappers**: ALWAYS use `bundle exec` or `bin/` wrappers.
- **Safety Guards**: Respect the guards in `spec/rails_helper.rb`. If you hit a "FATAL ERROR," stop and re-evaluate your environmental context.

### 2. Infrastructure Standards
- **Local-First**: We depend on local llama.cpp on port 11500.
- **Concurrency**: We use Solid Queue with weight-based throttling.

## 🛠️ Development Workflow

1.  **Issue First**: Ensure an issue exists (local or GitHub) before starting work.
2.  **Backlog Sync**: Use the `backlog` tools to track your progress through the implementation DAG.
3.  **PR Expectations**:
    - All new features must include RSpec coverage.
    - Architectural changes must not violate `packwerk` boundaries.
    - Security warnings (Brakeman) must be resolved or formally ignored in `config/brakeman.ignore`.

## 📐 Coding Standards

- **Rails Idioms**: Follow "Convention over Configuration." Use native helpers and established framework patterns.
- **Fewer, Better Docs**: Document the "Why" and the "Boundaries," not the implementation details.
- **Deterministic AI**: When working on LLM prompts, ensure they are stored in `app/prompts/` and versioned.

## 🔐 Security & Safety

- **Credentials**: Never commit secrets or unencrypted keys. Use `bin/rails credentials:edit` for all sensitive configuration.
- **Data Privacy**: Ensure that `User` data remains strictly isolated. Vector searches must always be scoped to the authenticated user's resume track.

## 🏗️ Adding a New Ingestion Source

1.  Create a new adapter class in `packages/ingestion/app/services/`.
2.  Register the source in `config/initializers/ingestion_adapters.rb`.
3.  Add an Extraction Contract spec to verify the board's structure.

## 📝 Documentation

Updates to the core logic require corresponding updates to:
- `CONTEXT.md` (if domain language changes).
- `README.md` (if prerequisites or setup changes).
- An ADR in `docs/adr/` (for significant architectural decisions).
