# Documentation Index

Welcome to the WWWorkRemote documentation nodes.

## 🗺️ Documentation Map

### Core Guides
- **[README.md](../README.md)**: Project overview and quick start.
- **[CONTRIBUTING.md](../CONTRIBUTING.md)**: Workflow, standards, and engineering mandates.
- **[Development](development.md)**: Local setup, prerequisites, and common tasks.
- **[Testing](testing.md)**: RSpec strategy, contracts, and VCR usage.
- **[Architecture](architecture.md)**: Subsystems, data flow, and "Solid" stack.
- **[Configuration](configuration.md)**: Environment variables and credentials.
- **[Troubleshooting](troubleshooting.md)**: Common failures and fixes.
- **[Deployment](deployment.md)**: Disaster recovery and scaling.

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
