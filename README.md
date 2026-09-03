# WWWorkRemote: The Autonomous Remote Job Synthesis Engine

> "Searching for remote work shouldn't be a second full-time job."

WWWorkRemote is a high-performance, domain-driven engine for aggregating, synthesizing, and ranking remote job opportunities. It leverages local LLMs and vector search to provide high-leverage market intelligence.

## 🚀 Quick Start

```bash
# 1. Setup dependencies and database
bin/setup

# 2. Sync AI model registry
bin/rails ruby_llm:load_models

# 3. Start development server
bin/dev
```
Access the dashboard at `http://localhost:31000`.

## 📚 Canonical Documentation

- **[docs/development.md](docs/development.md)**: Local setup, prerequisites, and common workflows.
- **[docs/architecture.md](docs/architecture.md)**: Subsystem boundaries, data flow, and "Solid" infrastructure.
- **[docs/testing.md](docs/testing.md)**: Test strategy, extraction contracts, and local CI.
- **[docs/configuration.md](docs/configuration.md)**: Environment variables and encrypted credentials.
- **[docs/troubleshooting.md](docs/troubleshooting.md)**: Common failures and recovery steps.
- **[CONTRIBUTING.md](CONTRIBUTING.md)**: Standards, PR expectations, and adding new sources.

## 🛠️ Key Commands

| Command | Purpose |
| :--- | :--- |
| `bin/dev` | Start the Falcon app server and workers. |
| `bin/setup` | Idempotent system bootstrap. |
| `bin/update-geoip` | Download latest MaxMind databases. |
| `bin/wwwr status` | Pipeline health from the shell (`bin/wwwr --help` for the rest). |
| `bin/wwwr interview-prep <id>` | Generate an interview prep pack — human + read-aloud (text-to-speech) versions. `--export` writes them to `~/ai/outbox/`. See [docs/interview-prep/](docs/interview-prep/README.md). |
| `bundle exec rspec` | Run the test suite. |

---

## ⚖️ License

Copyright &copy; 2024-2026 Mike Hall. Proprietary software. Unauthorized distribution prohibited. See [LICENSE](LICENSE).
