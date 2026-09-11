# Troubleshooting

This document covers common failures and recovery steps for WWWorkRemote.

## 🤖 AI & LLM Issues

### "Connection Refused" (localhost:11500)
**Symptoms**: Ingestion fails, match scores are 0%, or errors in `development.log`.
**Cause**: The llama.cpp or Ollama server is not running or on the wrong port.
**Fix**:
1. Ensure your local LLM server is active.
2. Verify `OLLAMA_API_BASE` in your environment.
3. Check the "Model Registry" view in the app to see if the `local` model is detected.

### "No model found in registry"
**Symptoms**: LLM calls fail immediately with a "No model provided" error.
**Cause**: The database model table is empty or out of sync with `config/models.yml`.
**Fix**: Run the synchronization task:
```bash
bin/rails ruby_llm:load_models
```

## 🏗️ Infrastructure Issues

### GeoIP Database Missing
**Symptoms**: Job postings show "Location: Unknown" or geocoding jobs fail.
**Cause**: `GeoLite2-City.mmdb` is missing from `data/maxmind/`.
**Fix**:
1. Ensure credentials are set.
2. Run `bin/update-geoip`.

### Database Connection Timeout
**Symptoms**: App hangs or shows 500 errors during heavy ingestion.
**Cause**: The connection pool is exhausted by concurrent fiber-based jobs.
**Fix**: Increase `pool` size in `config/database.yml` or reduce worker concurrency in `config/sidekiq.yml` (though we use Solid Queue, check `config/queue.yml`).

## 🧪 Test Failures

### System Tests failing with "Model not found"
**Symptoms**: `RSpec` system specs fail in the server thread.
**Cause**: Transactional fixture isolation prevents the server thread from seeing models seeded in the test thread.
**Fix**: We have implemented a global stub in `rails_helper.rb` for system tests. Ensure `type: :system` is correctly set on the spec.

### External Network Errors
**Symptoms**: `YC Scraper Contract` or other live specs fail with 406 or Timeout.
**Cause**: 3rd party site has updated bot protection or is down.
**Fix**:
1. If it's a permanent change, update the Scraper and re-record the VCR cassette.
2. Use `VCR.eject_cassette` to re-record.
