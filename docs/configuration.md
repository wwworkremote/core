# Configuration Guide

WWWorkRemote uses a combination of Environment Variables and Encrypted Credentials to manage configuration across different environments.

## 🔐 Encrypted Credentials

Sensitive keys (API keys, secret tokens) are managed via Rails Encrypted Credentials.

To edit credentials:
```bash
EDITOR="code --wait" bin/rails credentials:edit
```

### Required Keys
| Key | Purpose |
| :--- | :--- |
| `openai_api_key` | Optional, for OpenAI/OpenRouter fallback. |
| `anthropic_api_key` | Required for Claude 3.5 Sonnet fallback. |
| `geoip.license_key` | Required for MaxMind GeoIP updates. |

## 🌍 Environment Variables

Environment variables are used for infrastructure pointers and non-secret overrides.

| Variable | Default | Purpose |
| :--- | :--- | :--- |
| `OLLAMA_API_BASE` | `http://localhost:11500/v1` | URL for the local llama.cpp / Ollama server. |
| `ENABLE_EMBEDDINGS` | `true` | Toggle vector generation. Set to `false` if local server is down. |
| `MAXMIND_ACCOUNT_ID` | (null) | Required for `bin/update-geoip`. |
| `DATABASE_URL` | (rails default) | PostgreSQL connection string. |

## 🛰️ External Services

### Local LLM (llama.cpp)
By default, WWWorkRemote expects a llama.cpp server running with the following configuration:
- **Port**: 11500
- **Endpoint**: `/v1/embeddings` and `/v1/chat/completions`
- **Model Alias**: `local` (must be configured in `config/models.yml`)

### GeoIP Updates
Geolocation requires the MaxMind Lite database.
1. Set `MAXMIND_ACCOUNT_ID` and `MAXMIND_LICENSE_KEY`.
2. Run `bin/update-geoip`.
3. Databases are stored in `data/maxmind/` (usually symlinked to system paths).

## 🚩 Feature Flags
System-wide settings can be toggled via the **Ingestion Control** dashboard at `/data_fetchers`.
- **Global Pause**: Instantly stops all background ingestion and AI processing.
