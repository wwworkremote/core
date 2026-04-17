# WWWorkRemote: The Ultimate Rails Job Engine

Bleeding-edge data acquisition engine and dashboard for remote job listings, powered by the "Ultimate Rails Platform Stack."

## 🚀 The Stack
- **Ruby 4.0.2:** Bleeding-edge performance and features.
- **Rails 8.2.0.alpha:** Tracking the `main` branch for the latest framework innovations.
- **Sidekiq 8.1.3:** Robust, high-performance background processing.
- **Solid Infrastructure:**
  - `solid_cache`: Database-backed caching.
  - `solid_queue`: Database-backed background jobs.
  - `solid_cable`: Database-backed Action Cable.
- **Modern Asset Pipeline:** Propshaft, DartSass, and Importmaps (no-build JS).
- **Search & AI:**
  - `pgvector`: Semantic similarity search on host PostgreSQL.
  - `PgSearch`: Advanced full-text search with trigram support.
  - `llama.cpp`: Local AI integration for job categorization and embeddings.

## 🛠 Getting Started

### Default Port
The application listens on port **3010** by default.

### Local Development (Host)
Ensure you have Ruby 4.0.2 and PostgreSQL (with `pgvector`) installed on your host machine.

```bash
# Install dependencies
bundle install

# Run migrations (on host DB)
bin/rails db:migrate

# Start development server and assets watcher
./bin/dev
```
Access the dashboard at: `http://localhost:3010`

### Local Development (Docker)
The environment is containerized but connects to your **host machine's PostgreSQL** for high-performance search capabilities.

```bash
# Start background services (Redis, Jaeger) and application
docker-compose up -d

# Verify scheduled fetchers
docker-compose exec web bin/rails runner "puts Sidekiq::Cron::Job.all"
```

## 🛰 Data Acquisition

### Supported Sources
- **Greenhouse:** Direct employer API with keyword filtering.
- **Lever:** Direct employer API with keyword filtering.
- **YC (Work at a Startup):** Curated startup jobs via specialized scraper.
- **Jobicy / Arbeitnow / Remotive / WWR:** Broad remote-first APIs and feeds.
- **Hacker News:** Real-time job story ingestion.

### Triggering Ingest
To manually trigger a fresh fetch of all jobs across all platforms:
```bash
./bin-host/fetch-all
```

## 🔍 Advanced Search
- **Text Search:** `JobPosting.search("Ruby on Rails")` (Ranked by relevance).
- **Semantic Search:** `JobPosting.semantic_search("Staff level backend roles in AI")` (Context-aware).
- **Intersection Analysis:** Jobs track which specific query terms found them (`found_by_terms` metadata).

## 📊 Observability
- **OpenTelemetry:** Integrated with Jaeger for distributed tracing.
- **Sidekiq UI:** Monitor background jobs at `/sidekiq`.
- **PgHero:** Database performance insights available in development.

## 📝 Documentation
- [RUBY_LLM.md](./RUBY_LLM.md): AI integration and local LLM configuration.
- [PICKUP.md](./PICKUP.md): Recent architectural changes and port reconfigurations.
