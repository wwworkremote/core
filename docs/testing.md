# Testing Strategy

WWWorkRemote prioritizes behavioral correctness and contractual integrity between the ingestion engine and external data sources.

## 🧪 Test Suite

Run the full suite using RSpec:

```bash
bundle exec rspec
```

### Key Spec Areas
- **Extraction Contracts**: `packages/ingestion/spec/services/job_fetchers/extractor_contract_spec.rb` ensures scrapers don't break when 3rd party HTML structures change.
- **LLM Orchestration**: Tests in `spec/services/LLM/` use WebMock to simulate local and frontier model responses.
- **Guardrails**: `spec/services/guardrails/` verifies that untrusted text is properly sanitized.

## 🛡️ Contract Testing (Golden Cassettes)

We use **VCR** to record 3rd party API interactions.

- **Rule**: Never delete a VCR cassette unless the 3rd party API documentation has changed.
- **Live Mode**: To run specs against live endpoints (bypassing VCR):
  ```bash
  LIVE_INTEGRATION=true bundle exec rspec
  ```

## 🧹 Quality & Linting

We enforce strict architectural boundaries and code style:

- **Linting**: `bundle exec rubocop`
- **Architecture**: `bundle exec packwerk check`
- **Security**: `bin/brakeman`

## ✅ Local CI

WWWorkRemote supports running the full GitHub Actions pipeline locally using `act`. This is recommended before any major architectural push.

```bash
# Run all CI jobs locally
bin/ci
```
*Prerequisite: Docker must be running.*
