# RubyLLM Integration Notes

This project uses **RubyLLM 1.14.x** as a unified interface for AI providers.

## Architecture

- **Gem:** `ruby_llm` (≥1.14)
- **Persistence:** `LLMChat` and `LLMMessage` ActiveRecord models.
- **Admin:** Managed via Rails Admin Namespace at `/admin`.

## Ecosystem & Observability

This project leverages several RubyLLM ecosystem projects for enhanced functionality and visibility:

### Structured Data (`RubyLLM::Schema`)
Used for defining precise JSON schemas for LLM structured outputs and function calling.
- **Example:** Defining job categorization schemas.

### Instrumentation (`RubyLLM::Instrumentation`)
Exposes RubyLLM events via `ActiveSupport::Notifications`. Key events:
- `complete_chat.ruby_llm`
- `execute_tool.ruby_llm`
- `embed_text.ruby_llm`

### OpenTelemetry
Full observability into LLM applications via `opentelemetry-instrumentation-ruby_llm`.
- **Traces:** Chat completions and tool call flows.
- **Metrics:** Token usage (input/output) and Step durations.
- **Error Tracking:** Automatic recording of LLM-specific failures.

To see these traces, check the **Automation** tab in the Admin dashboard or your configured OTLP backend.

---

## Local Inference — llama.cpp

The primary local model runs via a **native llama.cpp server** managed by `llama-ctl`.
There is no Docker/Ollama dependency; the server exposes an OpenAI-compatible API.

| Setting | Value |
| :--- | :--- |
| Endpoint | `http://127.0.0.1:8080/v1` |
| Model alias (use in all API calls) | `local` |
| Active model | Qwen 2.5 Coder 7B Instruct (Q4_K_M) |
| Profiles | `standard`, `reasoning`, `constrained`, `embed` |
| Config | `~/.config/zsh/etc/ai-models.yaml` |

**Start/stop the server:**
```bash
llama-ctl start     # load launchd service
llama-ctl status    # health + active model
llama-ctl restart   # after config changes
```

**After changing `ai-models.yaml`:**
```bash
llama-ctl install && llama-ctl restart
```

## RubyLLM Configuration (`config/initializers/00_ruby_llm.rb`)

```ruby
config.openai_api_base  = 'http://localhost:8080/v1'   # inference
config.ollama_api_base  = 'http://localhost:8080/v1'   # embeddings
config.openai_use_system_role = true                   # llama.cpp needs 'system' not 'developer'
config.use_new_acts_as = true
```

The local model is registered with `provider: "ollama"` in `config/models.yml`.
RubyLLM routes Ollama calls through `config.ollama_api_base`, which points to the
llama.cpp server. Always use the string `"local"` as the model ID in API calls —
not the GGUF filename.

## Cloud Providers

Supported via environment variables / Rails credentials:

| Provider | Key |
| :--- | :--- |
| Anthropic | `ANTHROPIC_API_KEY` |
| OpenAI | `OPENAI_API_KEY` |
| Google Gemini | `GEMINI_API_KEY` |

## Embeddings (`app/services/job_boards/embedder.rb`)

Uses a direct Faraday POST to `/v1/embeddings` (not RubyLLM) with `model: "local"`.
The server must be started with `--embeddings` (handled by `llama-ctl`).

To switch to the dedicated embedding model (`nomic-embed-text`):
```bash
llama-ctl model-switch embed   # follow printed instructions
llama-ctl restart
```

## Validation

```bash
ruby bin/verify_llm.rb          # smoke test: one inference round-trip + latency
```

## Development & Testing

- LLM calls should be stubbed in RSpec (see `rails_helper.rb`).
- Model registry: run `bin/rails ruby_llm:load_models` to refresh the `models` table.
- **OpenStruct note:** `require 'ostruct'` is needed in Ruby 4.0+; already added to
  `app/services/llm/orchestrator.rb`.
