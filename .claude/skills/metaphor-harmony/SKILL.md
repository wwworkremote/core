---
name: metaphor-harmony
description: >-
  Audit, evaluate, and harmonize system metaphors, domain language (CONTEXT.md),
  and conceptual models against observed reality and core architecture principles.
  Use when designing new features, adding domain entities, reviewing PRs for
  conceptual integrity, or ensuring the Embodied Rider and Forensic Observer
  mental models resonate without cognitive dissonance.
metadata:
  version: 1.0.0
---

# Metaphor Harmony & System Cartography

WWWorkRemote models the job-search operating system using two complementary,
interlocking metaphor clusters grounded in **Reality-Driven Development**:

1. **The Embodied Rider (Kinetic Action & Bounded Agency)**
   - *The Pump Track* (`docs/architecture/pump-track.md`, `docs/adr/004`):
     Continuous momentum, terrain navigation, active pumping through four phases:
     Drop-in (Intake) → Bottom (Resolution) → Climb (Response Construction) → Berm (Reorientation).
   - *The Bounded Agency Harness* (`docs/adr/005`, `docs/adr/006`):
     The operator wears the harness. Automation provides mechanical assistance and
     telemetry, but at **Commitment Boundaries** (irreversible submission, data
     transmission), the harness locks for explicit human judgment.
   - *The Correlation Spine* (`docs/adr/010`, `docs/architecture/datalake.md`):
     The `session_token` / `application_trace_id` is the anatomical spine anchoring
     observations, mappings, answers, errors, and raw asset bundles into a single
     coherent run.

2. **The Forensic Observer (Empirical Evidence & System Cartography)**
   - *Datalake Modality* (`docs/architecture/datalake.md`):
     A sensory capture *modality* (like ultrasound or MRI), not an analytical database.
     Greedily captures raw DOM, HAR, and screenshots; extracts structure on read.
   - *Paleontological Taxonomy* (`docs/architecture/signature-registry.md`, `docs/adr/008`):
     *Question Occurrences* are immutable fossil specimens; *Question Archetypes* are
     taxonomic classifications; *Reference Scenarios* are holotype specimens.
   - *Panoramic View Cartography* (`docs/architecture/panoramic-view.md`):
     Wide-angle, cross-sectional slices across time and architectural depth. Honest
     narration of absence (`noop_trace`).

---

## The Audit Procedure

### 1. Identify Metaphor Collisions
Scan text, PRs, or proposals for telltale collision patterns:
- **The "Funnel" Trap**: Describing job search as a linear funnel with a terminal dead end.
  *Correction*: Reframe as the Pump Track loop. Getting hired changes terrain; it does not end the game.
- **The "Autopilot" Trap**: Describing AI as "submitting applications autonomously" or "auto-applying".
  *Correction*: Reframe under Bounded Agency. The system drafts and measures; Mike holds the reins at the Commitment Boundary.
- **The "Sinusoidal" Collision**:
  *Correction*: The macro workflow is a **Pump Track** (active momentum, not passive oscillation). The micro network traversal is an architectural **Topological Wave** through system layers (DOM → Extension → API → Service → DB → Response).
- **The "Database-First" Trap**: Demanding schema migrations before capturing novel ATS flows.
  *Correction*: Reframe under the Datalake Modality. Capture raw assets into session bundles first; extract structure on read.

### 2. Verify Vocabulary Against `CONTEXT.md`
- Challenge overloaded terms ("account", "user", "job", "lead").
- Distinguish strictly between raw observations (*Occurrences*) and synthetic groupings (*Archetypes*).
- Ensure new entities are added to `CONTEXT.md` Domain Language.

### 3. Dogfooding Ergonomics Check
- Test shell commands (`bin/wwwr`, `bin/wwwr-ctl`, `bin/wwwr-jobs`, `bin/wwwr-web`).
- Verify commands are fast, single-user focused, and require zero boilerplate `rails runner` copy-pasting.
- Verify that `man/wwwr.1` and shell completions are updated when new subcommands or flags land.

### 4. Panoramic View & PVL Boundary Guard
- Check adherence to the global naming rule: Panoramic View is a *technique* (system cartography); PVL is the initiative; zdots is the root local-system platform. wwworkremote applies the technique to application traces without appropriating the platform brand.
