# Development Guide

This document outlines the process for setting up and running WWWorkRemote in a local development environment.

## 📋 Prerequisites

Ensure your system has the following core dependencies:

- **Ruby 4.0.2**: Managed via `mise` or `asdf`.
- **PostgreSQL 16+**: Must support `pgvector` and `pg_trgm`.
- **Node.js**: Required for Tailwind and Ingestion scripts.
- **llama.cpp**: A local LLM server must be running at `http://localhost:11500`.
- **Docker**: Optional, required for running local CI via `act`.

## 🚀 Local Setup

Run the automated setup script to install dependencies and prepare the database:

```bash
bin/setup
```

### 1. AI Model Registry
WWWorkRemote requires localized model definitions in the database to orchestrate jobs:

```bash
bin/rails ruby_llm:load_models
```

### 2. GeoIP Databases
For local location resolution, download the MaxMind Lite databases:

```bash
# Set your MaxMind credentials
export MAXMIND_ACCOUNT_ID="your_id"
export MAXMIND_LICENSE_KEY="your_key"

bin/update-geoip
```

See [docs/configuration.md](configuration.md) for detail on credential management.

## 🛠️ Running the System

### Application Server
Start the development server (Falcon):

```bash
bin/dev
```
Access the dashboard at `http://localhost:31000`.

### Background Workers
WWWorkRemote uses **Solid Queue**. Workers are automatically started by `bin/dev` via the `Procfile.dev`.

### EML Scanner
To scan your local Apple Mail exports for job postings:

```bash
bundle exec rake eml:scan
```
*Expected path: `~/.wwworkremote/*.eml`*

## ✅ Operational Verification (Smoke Tests)

Confirm the system is healthy after a major update:

- **Email Ingestion**: Place a `.eml` in `~/.wwworkremote/indeed/` and run `bundle exec rake eml:scan`.
- **AI Inference**: Run `ruby bin/verify_llm.rb` to check connectivity and responses.
- **Background Queue**: Access Mission Control at `/mounts/jobs` and confirm workers are active.
- **Analytics**: Verify `/admin/observability` charts render correctly.

## 🔍 Debugging

- **Logs**: `tail -f log/development.log`
- **Job Monitoring**: Access the Mission Control dashboard at `/mounts/jobs`.
- **Database Performance**: Access PgHero at `/mounts/pghero`.
- **LLM Context**: Use the "Neural Dialogues" view to debug raw LLM prompts and responses.
