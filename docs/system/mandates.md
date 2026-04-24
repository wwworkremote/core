# 🛡️ WWWorkRemote Engineering Mandates

## 1. Database Safety & Environmental Context
**CRITICAL**: The development database (`wwworkremote_development`) contains high-fidelity, real-world data and MUST NEVER be reset, truncated, or modified by test suites.

- **Mandatory Prefix**: ALL shell commands that interact with the Rails stack MUST use an explicit `RAILS_ENV` prefix.
    - ✅ `RAILS_ENV=test bundle exec rspec`
    - ✅ `RAILS_ENV=development bin/rails runner '...'`
- **Standard Wrappers**: ALWAYS use `bundle exec` or `bin/` wrappers. Never call `rspec`, `rails`, or `rake` directly.
- **Guard Sovereignity**: The safety guard in `spec/rails_helper.rb` is the source of truth. If it triggers a "FATAL ERROR", the agent must stop immediately and re-evaluate the command's environmental context.

## 2. Infrastructure Standards
- **Local-First**: 100% dependency on local llama.cpp on port 8080.
- **Concurrency**: Use threaded mode and Solid Queue weight-based throttling as configured in `config/queue.yml`.
- **macOS Safety**: Maintain `gssencmode: "disable"` and single-worker Puma in development to avoid Signal 11 crashes.

## 3. Tooling Conventions
- **Tmux**: Commands in `bin/services` must never use `read` or `exit` to autoclose windows. Always drop to a fallback `bash` shell to preserve debug context.
