# Deployment & Disaster Recovery

WWWorkRemote is designed for resilient local-first or private-cloud deployment.

## 🚀 Deployment Model

The platform follows a **Single-Process, Multi-Fiber** model powered by **Falcon**.

### Stack Requirements
- **Runtime**: Ruby 4.0.2
- **App Server**: Falcon
- **Database**: PostgreSQL 16+ with `pgvector`
- **Queue**: Solid Queue (DB-backed)

### Infrastructure Scaling
For high-volume synthesis, we recommend a **Primary/Replica** database split:
- **Primary**: Handles ingestion writes and state changes.
- **Replica**: Handles heavy semantic searches and LLM context lookups.
- Configuration is managed in `config/database.yml`.

## 🛡️ Data Protection

### Automated Backups
Managed by `DatabaseBackupJob`.
- **Schedule**: Daily at 03:00 (see `config/recurring.yml`).
- **Path**: `data/backups/`.
- **Retention**: 7 days.

### Manual Restore
To restore from a `.dump` file:
```bash
pg_restore -c -d wwworkremote_production data/backups/full_backup_TIMESTAMP.dump
```

## 🚨 Recovery Procedures

### Database Corruption
1. Identity the last known good backup in `data/backups/`.
2. Restore via `pg_restore`.
3. Trigger a full re-ingestion for the missing window: `bin-host/fetch-all`.

### LLM Provider Failure
If the local server fails, the `LLM::Orchestrator` is designed to fall back to Claude (if `anthropic_api_key` is configured). Ensure your fallback models are registered in `config/models.yml`.
