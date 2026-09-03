# Documentation Index

Welcome to the WWWorkRemote documentation nodes.

This whole tree is browsable from inside the running app at `/docs` — including rendered Mermaid
diagrams, not just source. This file itself is best read there.

## 🗺️ Documentation Map

### Core Guides
- **[README.md](../README.md)**: Project overview and quick start.
- **[CONTRIBUTING.md](../CONTRIBUTING.md)**: Workflow, standards, and engineering mandates.
- **[Development](development.md)**: Local setup, prerequisites, and common tasks.
- **[Testing](testing.md)**: RSpec strategy, contracts, and VCR usage.
- **[Architecture](architecture.md)**: Subsystems, data flow, and "Solid" stack.
- **[Component Overview](architecture/component-overview.md)**: Diagram of how the major pieces collaborate.
- **[Pipeline Statechart](architecture/pipeline-statechart.md)**: The three independent state machines behind "what happened to this posting."
- **[Applying with the Harness](applying-with-the-harness.md)**: Operator runbook — one job link to a submitted application, step by step, marking what's automated vs by-hand vs not-built.
- **[Application Sequence](architecture/application-sequence.md)**: One posting's journey, start to finish, as a sequence diagram.
- **[Human Task Pipeline](architecture/human-task-pipeline.md)**: BPMN-lite Service Task/User Task split for AI-proposed, human-approved decisions (persona picks, drafted answers).
- **[Guided Session Flow](architecture/guided-session-flow.md)**: BPMN-lite Mermaid validation scheme for supervised posting-to-application laps, approval gates, and loop-back.
- **[Job Application Pump Track](architecture/pump-track.md)**: The recurring actor-system loop behind discovery, evaluation, application, and what comes next.
- **[Supervised Intent Capture ADR](adr/005-supervised-intent-capture.md)**: How guided sessions preserve Mike's intent while keeping automation bounded.
- **[BPMN-lite Guided Session ADR](adr/006-bpmn-lite-guided-session-validation.md)**: Why Mermaid validates the flow while ActiveRecord/AASM remain the runtime state tools.
- **[Business-Process Signals](architecture/business-process-signals.md)**: Truth seams and composite signals that prove the job-posting-to-application process is functioning.
- **[Business-Process Health Signals ADR](adr/007-business-process-health-signals.md)**: Why functional health is interpreted from ordered business signal sets.
- **[Panoramic View](architecture/panoramic-view.md)**: Design for a trace-correlated, read-only evidence timeline and supervised application session.
- **[Application Question Knowledge Graph](architecture/application-question-knowledge-graph.md)**: Cross-application map of observed question occurrences, archetypes, answer strategies, companies, industries, personas, and outcomes.
- **[Question Occurrence Preservation ADR](adr/008-preserve-question-occurrences-before-archetype-clustering.md)**: Why exact contextual observations remain separate from curated archetypes and reusable answers.
- **[Reference Comparison ADR](adr/009-reference-comparison-drift-and-coverage.md)**: How a guided session is materialized and compared against its provider Reference Scenario, separating coverage from drift and recording findings and human dispositions.
- **[Signature Registry](architecture/signature-registry.md)**: Mapping a scenario id against a remote site's own identifiers, with capture and human-approved references built.
- **[Sandbox Provider](architecture/sandbox-provider.md)**: A fake Greenhouse-shaped ATS served locally for safe extension dogfooding and Reference Scenario capture.
- **[Configuration](configuration.md)**: Environment variables and credentials.
- **[Troubleshooting](troubleshooting.md)**: Common failures and fixes.
- **[Deployment](deployment.md)**: Disaster recovery and scaling.

### Interview Prep
- **[Interview prep docs](interview-prep/README.md)**: The prep pack feature — the read-aloud (text-to-speech) standard, the transform prompt for external TTS tooling, and one worked reference per role, plus the export-and-integration guide for wiring up a text-to-speech tool.
- **[Interview prep tooling](architecture/interview-prep-tooling.md)**: How it fits together — generation, the read-aloud rewrite, storage, the export, and the audit loop, with sequence and pipeline diagrams.

### Research Notes
- **[Chrome built-in AI flags](research/chrome-built-in-ai-flags.md)**: Which browser AI flags help or interfere with the extension and guided-session dogfooding.
- **[Chrome platform and WASM leverage](research/chrome-platform-and-wasm-leverage.md)**: Ranked opportunities for CDP, Offscreen Documents, WASM inference, and future harness work.

### Special Interest
- **[Changelog](changelog.md)**: Narrative project history by era, from git log + Backlog.md.
- **[ADR Registry](adr/001-audit-strategy.md)**: Architecture Decision Records.
- **[Agent Protocol](agents/domain.md)**: Context and guides for AI Agents.
- **[Extension Guide](../extension/README.md)**: Ingestion Assistant Chrome Extension.
- **[Extension Workflow](extension-workflow.md)**: Provider coverage, extraction tiers, live-verification log.
- **[OpenAPI Spec](architecture/openapi.yaml)**: Request/response shapes for the extension <-> Rails bridge.
- **[just3ws Interop Protocol](just3ws-interop-protocol.md)**: Cross-tool scoring/data-exchange contract.
- **[Backlog](../backlog/)**: Task tracking (Backlog.md MCP).

### Agent-Facing Guides (`docs/agents/`)
- **[bin/ Scripts Index](agents/bin-scripts.md)**: What every `bin/*` script does and when to use it.
- **[bin/ Script Conventions](agents/bin-script-conventions.md)**: Rules for writing new scripts safely (test-DB isolation, etc).
- **[Interop](agents/interop.md)**: How external local tools (e.g. `just3ws`) should call into this app.
- **[Issue Tracker](agents/issue-tracker.md)**: GitHub Issues conventions via `gh`.
- **[Triage Labels](agents/triage-labels.md)**: Standard label roles for issue triage.

### CLI Help
- `bin/wwwr --help` — pipeline status, browse postings, trigger transitions from the shell.
- `bin/verify_board --help` — confirm a new ADP/Workday/Greenhouse/Lever tenant slug works before adding it to seeds.
