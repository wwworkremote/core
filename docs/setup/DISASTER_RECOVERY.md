# Disaster Recovery and Data Protection

This document outlines the strategy for ensuring data integrity and availability for the WWWorkRemote platform.

## 1. High Availability (Read Scaling)
The application is configured for a **Primary/Replica** architecture.
- **Primary (Writing)**: Handles all `POST/PATCH/PUT/DELETE` requests and ingestion updates.
- **Replica (Reading)**: Handles all `GET` requests and heavy analytical queries (e.g., semantic search, embeddings).
- **Configuration**: Managed in `config/database.yml` and `app/models/application_record.rb`.
- **Automatic Switching**: Rails automatically routes reads to the replica with a 2-second "consistency delay" for recently written data.

## 2. Automated Logical Backups
- **Tool**: `DatabaseBackupJob` (ActiveJob).
- **Format**: Postgres Custom Format (`.dump`) using `pg_dump -Fc`.
- **Schedule**: Nightly at 3:00 AM (configured in `config/recurring.yml`).
- **Location**: Backups are generated in `tmp/` and should be configured to upload to offsite S3-compatible storage.

### Restoration Procedure
To restore from a logical dump:
```bash
pg_restore -d your_database_name tmp/wwworkremote_backup_TIMESTAMP.dump
```

## 3. Continuous Archiving (PITR)
For production environments, **Point-In-Time Recovery (PITR)** is recommended at the infrastructure level.
- **Mechanism**: WAL (Write-Ahead Log) archiving.
- **Tool Recommendation**: [pgBackRest](https://pgbackrest.org/) or [WAL-G](https://github.com/wal-g/wal-g).
- **Process**:
    1. Enable `archive_mode = on` in `postgresql.conf`.
    2. Configure `archive_command` to push WAL segments to offsite storage.
    3. Perform periodic base backups.

## 4. Disaster Scenarios
### Scenario A: Primary Database Failure
1. Promote the Replica to Primary.
2. Update the `DATABASE_URL` in the application environment.
3. Restart application services.

### Scenario B: Data Corruption
1. Identity the timestamp of corruption.
2. Use PITR tools to restore the database to the minute *before* corruption occurred.
