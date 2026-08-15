# System Architecture

WWWorkRemote is a domain-driven Rails application designed for high-performance data acquisition and AI-powered synthesis.

## 🏛️ Core Architectural Pillars

### 1. Modular Ingestion (`packages/ingestion`)
The ingestion engine is isolated from the core application logic.
- **Seam**: It interacts with Core only via the `JobPosting` model and `JobBoards::Document` transition table.
- **Adapter Registry**: Sources (LinkedIn, WWR, etc.) are registered as independent adapters, allowing for high-velocity board integration without affecting core stability.
- **Resilience**: `ApiGuard` implements distributed circuit breakers to prevent bot-detection cascades.

### 2. Neural Orchestration Layer
Located in `app/services/LLM/`, this layer manages all interaction with language models.
- **VectorIntelligence**: A centralized seam for `pgvector` operations. All models (`Resume`, `Skill`, `JobPosting`) delegate embedding and ranking here.
- **Orchestrator**: A "Local First, Frontier Fallback" executor. It attempts local inference (`llama.cpp`) for categorization and falls back to Claude for complex synthesis.
- **Guardrails**: A non-bypassable pipeline that normalizes and validates all untrusted text before LLM submission.

### 3. Data Flow

1.  **Ingestion**: Scrapers/Fetchers capture raw data -> `JobBoards::Document`.
2.  **Normalization**: `Syncer` converts raw data to Markdown -> `JobPosting`.
3.  **Synthesis**: `Categorizer` (LLM) and `Embedder` (Vector) process the posting.
4.  **Resonance**: `JobSearch` campaigns rank postings based on user `Resume` embeddings.

## 🧠 AI Architectural Principles

The system implements a production-grade AI stack designed for reliability, safety, and deep technical alignment.

### 1. Robust LLM Orchestration & Provider Registry
- **Unified Interface**: `LLM::Orchestrator` abstracts disparate providers (Anthropic, OpenAI, Gemini, Ollama) into a single call pattern.
- **Provider Registry**: A dedicated `Model` registry manages capabilities, token windows, and provider-specific metadata.
- **Observability**: Native OpenTelemetry integration for tracing LLM latency, token usage, and failure modes.

### 2. Multi-Layered Guardrails & Safety Pipeline
- **Adversarial Mitigation**: `Guardrails::Normalizer` handles pathological input before inference.
- **Heuristic Scanning**: Fuzzy-matching detection of prompt injection and "jailbreak" attempts.
- **Classification Engine**: Risk-based disposition based on instruction density and pattern weights.

### 3. Vector-Native RAG Architecture
- **Semantic Identity**: `Resume::ProfileEmbedder` synthesizes work history and career goals into 768-dimensional embeddings.
- **Efficient Retrieval**: Native `pgvector` integration for matching profiles against job postings.

## 📜 Architectural Decisions (ADR Summary)

### ADR 001: Audit Strategy
Remove Rails Event Store (RES) and utilize **PaperTrail** for field-level auditing.

### ADR 002: Ultimate Stack Consolidation
Shift to **Solid** stack (`solid_queue`, `solid_cache`, `solid_cable`) to eliminate Redis dependencies.

### ADR 003: Distributed Circuit Breaker
Implement a non-blocking locking mechanism in `ApiGuard` using `Rails.cache` to handle HTTP 429 errors.

### ADR 004: Unified AI Orchestration
Centralize LLM interactions through a provider-agnostic Orchestrator and Guardrail pipeline.

## 🚀 Performance & Scaling

- **Falcon/Fibers**: The system utilizes a fiber-based concurrency model to handle non-blocking I/O during heavy LLM calls.
- **Solid Stack**: We utilize the "Solid" trio (`SolidQueue`, `SolidCache`, `SolidCable`) to eliminate Redis dependencies and keep all state in PostgreSQL.
- **Read Scaling**: The application supports a Primary/Replica architecture for distributing heavy analytical queries. See [docs/deployment.md](deployment.md) for disaster recovery info.
