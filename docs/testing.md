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

## 🔁 Focused development loop

Guard watches the Rails, view, and spec files and reruns only the affected
RSpec examples. The companies/sources loop is isolated for UI work:

```bash
bundle exec guard -g companies
```

SimpleCov is started by `spec/rails_helper.rb` for every Guard-triggered Rails
spec run. Coverage is written to `coverage/`; open `coverage/index.html` to
inspect the current run. Run one example directly when narrowing a failure:

```bash
bundle exec rspec spec/requests/companies_spec.rb:24
```

## ✅ Full check before a risky change

There is no CI service (solo project, GitHub Actions retired). The everyday loop
runs in the Overcommit hooks: RuboCop + working-tree-scoped RSpec + ESLint on
commit, Brakeman on push. Before a large or risky change, run the whole thing on
a clean tree yourself:

```bash
bundle exec rubocop
bundle exec brakeman -q -n -w2
bundle exec bundle-audit check --update
bin/rails db:test:prepare && bin/rails tailwindcss:build
bundle exec rails runner 'puts :ok'
RAILS_ENV=test bundle exec rspec spec packages/ingestion/spec
```
