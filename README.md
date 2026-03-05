# WWWorkRemote

Consolidated data acquisition engine and dashboard for remote job listings.

## Supported Sources

- **Hacker News:** (Active) Fetches job stories via the Firebase API.
- **Workable:** (In Development) Transitioning from XML feed to REST API v3.

## Infrastructure

The project runs in a containerized environment using Docker and Docker Compose.

- **Web:** Rails 7.2 application (Unified dashboard + ingestion logic).
- **Worker:** Sidekiq for background processing.
- **AI/LLM:** RubyLLM integrated with Ollama (local) and cloud providers. See [RUBY_LLM.md](./RUBY_LLM.md) for details.
- **Database:** PostgreSQL 15.
- **Cache/Queue:** Redis 7.

## Data Acquisition

To manually trigger a job fetch from the host:
```bash
./core/bin-host/fetch-jobs
```
