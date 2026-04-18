# RubyLLM Integration Notes

This project uses **RubyLLM** to provide a unified interface for interacting with various AI providers.

## Architecture

- **Gem:** `ruby_llm`
- **Persistence:** Database-backed chats and messages.
- **Admin:** Managed via native Rails **Admin Namespace** at `/admin`.

## Models & Providers

### Local AI (Ollama)
We use a Docker-managed Ollama instance for local inference.

**Internal Endpoint:** `http://ollama:11434` (accessible from `web` and `worker` containers).

#### Recommended Models for Job Analysis
| Model | Size | Best For |
| :--- | :--- | :--- |
| **Llama 3.2 1B** | ~1.3GB | Ultra-fast extraction of structured data (JSON). |
| **Llama 3.2 3B** | ~2.0GB | Summarization and basic reasoning. |
| **Phi-3.5 Mini** | ~2.3GB | Complex logic and multi-step instructions. |

### Cloud Providers
The following providers are supported via environment variables:
- **OpenAI:** `OPENAI_API_KEY`
- **Anthropic:** `ANTHROPIC_API_KEY`
- **Google Gemini:** `GEMINI_API_KEY`

## Getting Started with Ollama

1. **Pull a model:**
   ```bash
   docker-compose exec ollama ollama pull llama3.2:1b
   ```

2. **Basic Usage in Rails:**
   ```ruby
   # Create a chat session
chat = LlmChat.create!(model: 'llama3.2:1b', provider: 'ollama')

   # Send a prompt
response = chat.ask('Analyze this job post: [description]')
   ```

## Development & Testing

- **Stubs:** Geocoder and LLM calls should be stubbed in RSpec (see `rails_helper.rb`).
- **Registry:** 1,159+ models are pre-loaded in the `models` table. Run `bin/rails ruby_llm:load_models` to refresh.
