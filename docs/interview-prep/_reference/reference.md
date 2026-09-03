---
name: interview-prep-reference-example
description: >-
  Synthetic worked example of an interview prep pack — the quality bar generated
  packs are measured against. Part 1 is a fully fictional worked example
  (company, role, candidate, and referrer are invented); Part 2 is the
  per-section spec the generator follows.
metadata:
  type: reference
  version: 2.0.0
---

# Interview prep pack — reference example

**This is a synthetic example.** "Wayfare Logistics", the role, the candidate's
history, and the referrer are all invented, so this doc can live in the repo as
the generator's quality bar without carrying anyone's real interview prep. A real
generated pack lives on the `UserJobPosting` and renders on the posting page; it
is never committed here.

**Format.** Human-format — a reference read by people and agents, not fed to a
speech engine. The generated pack ships in two versions (human + read-aloud); the
read-aloud one follows [`../tts-readable-documentation.md`](../tts-readable-documentation.md).

---

## Part 1 — The prep pack (worked example)

### The setup

**Role.** Senior Software Engineer — Matching Platform. The team owns the service
that pairs open freight loads with available carriers in real time (hundreds of
matches/sec, sub-200ms budget from load posting to first carrier notification).
Mandate: keep the match quality high as volume grows, build the integrations
between the shipper-facing app and the matching engine, and drive projects
concept → production. Stack: **TypeScript/React front end, Go + Python services**,
Postgres/Redis/Kafka, gRPC, Kubernetes on GCP. Explicitly want someone **current
on AI-assisted development workflows** and comfortable owning a service end to end.

**Company.** Wayfare Logistics — Series C, ~600 people, digital freight brokerage
+ a carrier/shipper SaaS. Revenue = brokerage margin on booked loads + SaaS
subscription + payments/factoring fees. Culture signals in the posting and on
review sites: strong engineering-blog presence, "we deploy 30×/day", generous
learning budget, a stated no-on-call-heroics norm. Two consecutive "best place to
work" regional awards.

**Comp reality.** Posted band is a range; treat the midpoint as the anchor and
confirm early whether it holds for a senior hire at the candidate's location.
Don't negotiate in a rapport call. Before investing in later rounds, get the
**leveling** answer: is "Senior" the ceiling on this team, or is there a
Staff/Principal track above it, and is the band real.

**Title read.** If the résumé shows a Staff/Principal or lead title, expect "why a
Senior role, won't you be bored, why not a lead seat." Needs a real answer (see
the story arc).

### Domain primer — real-time freight matching / digital brokerage

**The business.** Wayfare is a broker: a shipper posts a load (origin,
destination, pickup window, equipment type, weight), and Wayfare finds a carrier
to haul it, taking a margin between the shipper rate and the carrier rate. The
**matching platform** is the piece that turns "here's a load" into "here's the
right truck, notified, in seconds"; the **shipper app** and **carrier app** are
where humans post loads, accept tenders, and track shipments. This role lives on
the **seam between the apps and the engine** — the apps are the system of record
for a load's state, the engine is the decision system, and they have to stay
consistent without double-booking a truck or a driver.

**MUST know for this interview** — each term expanded and bound to the body that
defines it, so the primary source is chase-able:

| Term | One line | Defined by |
|---|---|---|
| Load / shipment / lane | A load is one freight movement; a lane is an origin–destination pair; carriers price by lane. | FMCSA (Federal Motor Carrier Safety Administration) glossary; industry usage |
| Tender / accept / tender-reject | The broker "tenders" a load to a carrier; the carrier accepts or rejects within a window. Reject rate is a core health metric. | Standard EDI 204 (load tender) / 990 (response) transaction set, ASC X12 |
| Spot vs contract rate | Spot = one-off market price (volatile); contract = pre-negotiated rate over a period. The matcher weighs both. | DAT / Truckstop rate indices; industry usage |
| Deadhead | Miles a truck drives empty to reach a pickup. Minimizing it is a big part of match quality. | FMCSA / ATA (American Trucking Associations) |
| HOS / ELD (Hours of Service / Electronic Logging Device) | Federal limits on driving hours, enforced by an in-cab device. A match is only valid if the driver has hours left. | FMCSA 49 CFR Part 395 |
| ETA / geofence | Predicted arrival time; a geofence is a virtual boundary that fires an event when a truck enters/exits (pickup, delivery, checkpoint). | Company / vendor telematics APIs; OGC (Open Geospatial Consortium) for the geometry |
| Match score | The ranked fitness of a carrier for a load — distance, rate, on-time history, equipment, HOS feasibility, lane preference. | Internal model |
| Detention / accessorials | Extra charges beyond the line-haul rate (waiting at a dock, extra stops). | Industry usage; carrier contracts |
| Factoring | A carrier sells its invoice for immediate cash at a discount; brokers often offer it. | Industry usage |

**Useful context (know it exists):** power-only vs drop-and-hook; reefer vs dry
van vs flatbed; drayage; less-than-truckload (LTL) vs full truckload (FTL);
RMIS/carrier onboarding and compliance; SmartWay; multi-stop and continuous-move
optimization; the DAT/Truckstop load-board ecosystem the industry still runs on.

**Domain best practices an interviewer expects you to reach for:**
- The match path is soft-real-time: latency budgets end to end, timeouts as
  first-class (a slow match loses the truck to a competing broker), no synchronous
  third-party calls in the hot path, degrade gracefully to a smaller candidate set.
- App ↔ engine convergence via idempotency + eventual consistency — a load edit or
  a cancellation in the app must reach the matcher without double-booking or a
  ghost tender.
- Capacity/booking as a distributed reservation problem, not a single transaction —
  you can't strongly-lock every truck across every region.
- Feature-flag every scoring change — a bad weight sends trucks the wrong way and
  costs real margin within an hour.
- Event volume is large (every ping, geofence, status change) → columnar storage,
  sampling, pre-aggregation for analytics.

**Blind spots given a fintech / platform-modernization background:**
- **Decisions expire.** A loan approval is durable; a match is valid for seconds —
  the truck moves, the driver's hours tick down, a competitor books it. Same
  bounded-agency instinct, very different freshness tolerance.
- **The physical world is the source of truth and it's noisy** — GPS drift,
  drivers who don't update status, weather. The model has to be robust to bad
  inputs, not assume clean data.
- **Two-sided marketplace dynamics** — optimizing purely for shipper price starves
  carrier supply; you're balancing both sides, not serving one.
- **Regulatory hard constraints** — HOS/ELD isn't a preference, it's the law; a
  match that violates it is a defect, not a low score.
- **Fraud is adversarial** — double-brokering, identity spoofing of carriers,
  fake MC numbers — and it shapes the onboarding and matching architecture.

**Learning resources** (verify links before relying on them):
- FMCSA — HOS rules (49 CFR Part 395), the SAFER / carrier lookup system.
- ASC X12 — the EDI 204/214/990 transaction sets the industry runs on.
- DAT and Truckstop — rate indices and the load-board model; their engineering/
  data blogs.
- Industry press — FreightWaves, Transport Topics — for landscape and current events.
- The company's own engineering blog + product pages — how they frame the
  apps ↔ engine split.
- Engineering write-ups on real-time matching / dispatch systems and on
  reservation/inventory consistency at scale.

### The story — 90-second arc

Give a throughline, not a chronology:

> ~18 years, started in enterprise back-end work, moved to services and platform
> engineering through a local software community. Since then the work has had one
> shape: **go into a system that matters, is tangled, and can't go down — and make
> it safe to change.** At [Company A], replaced a risky big-bang rewrite with a
> strangler-fig migration behind an internal gateway. At [Company B], ran
> zero-downtime database and framework upgrades under live traffic. At [Company C]
> (the longest stretch), shipped a customer-facing product concept-to-prod, stood
> up a new enablement team, and led an org-wide observability rollout across
> several very different runtimes.
>
> The last year-plus I've gone deep on **AI-augmented engineering** — MCP servers
> exposing live telemetry to coding agents, a local-first LLM stack, agent
> guardrails.
>
> What I want next: back to **hands-on product building** on a team that's glad to
> have me, where the work is bridging two real systems — which is exactly what
> this role is.

That last line is the answer to the down-level question: hands-on, no desire to
manage right now, right-sized to the company, culture fit is real.

### Company-specific hooks (use 2–3, don't force all)

- **"Integrations between the apps and the matching engine"** = the internal
  gateway isolating legacy services at [Company A] + decoupling two domains at
  [Company C]. Best match — lead with it.
- **"Keep match quality high as volume grows"** — a taxonomy/consistency service
  that killed drift across teams; taking a gnarly backend capability and making it
  a clean product flow.
- **AI-assisted workflows** — past "I use an autocomplete tool": MCP servers,
  local inference for sensitive data, prompt-injection guardrails, agent context
  budgeting. Differentiator; have one concrete story ready.
- **Sub-200ms / high-volume** — real-time inventory work, high-QPS fraud queries,
  distributed tracing across a monolith + services.
- **Domain (bonus)** — be honest: not deep logistics, but marketplace/fraud/
  taxonomy work is adjacent. Frame as fast ramp, not existing expertise.

### The referral play

If a `Contact` is linked to the posting: **reach out the night before.**
1. Thank them.
2. Ask **what they told the team**, so the story matches the version already in the room.
3. Ask **what the role/team is actually like, who's on the panel, and whether the
   band is real** for a senior hire.

In the interview: name them warmly, tie it to how you actually know each other
(a real relationship, not a cold referral), then move on — don't lean on it past
the first few minutes. If there's no linked contact, this section is omitted.

### Likely questions

- "Why this role / aren't you overqualified?" → hands-on product building,
  bridge-two-systems is the wheelhouse, culture fit, not looking to manage now.
- "A project you drove concept → production." → the customer-facing product from
  [Company C].
- "Hardest production incident." → the silent-data-loss bug + the datastore
  migration under load.
- "How do you use AI in your workflow?" → one concrete MCP/agent story, grounded,
  not hype.
- "Front-end experience?" → production React at [Company A]; comfortable
  full-stack, back-end is the deeper side.
- "Why leave your last role?" → clean, non-bitter version.
- "What do you know about freight / logistics?" → honest + fast-ramp framing.

### Questions to ask them

- What does the apps ↔ engine seam look like today — where does it hurt most?
- What's the first project I'd own?
- How is the team leveled — is Senior the top of this track, or is there Staff/
  Principal above it?
- How do you actually use AI-assisted development day to day — house tools,
  guardrails, review norms?
- What does "sub-200ms" cost you operationally — where's the reliability pressure?
- The "best place to work" awards and the no-heroics norm — what's real about that
  vs. the plaque?

### Night-before checklist

- [ ] Confirm the meeting: time + timezone, format, link/dial-in, who's on it,
      accommodations contact.
- [ ] Reach out to the referral contact if there is one.
- [ ] Pull up the exact résumé + application answers that were submitted, so the
      story matches the doc they hold.
- [ ] Re-read the posting once more.
- [ ] Pick 2 AI stories + the concept-to-prod story; say them out loud once.

---

## Part 2 — Generalized shape (spec input for the feature)

What the generator produces, per section, and where each part's material comes from:

| Section | Kind | Source material |
|---|---|---|
| **The setup** — role summary, team, stack, comp reality, title-level delta | researched + derived | `JobPosting` fields + Lever/ATS raw + résumé archetype for the level-delta call |
| **Domain primer** — the industry knowledge *this* role assumes: business/money-flow + where the role sits, must-know vs useful-context vocabulary, domain best practices, blind spots for this candidate's background, learning resources | generated (model knowledge, posting-anchored) | `JobPosting` body/responsibilities/stack + candidate `History` (to compute blind spots). No live research in v1 — links are model-suggested and flagged "verify". Prompt guardrails: "useful context" = domain concepts not the candidate's own stack; "blind spots" = domain assumptions not the candidate's skill gaps; every acronym expanded **and** bound to the authority that defines it (a standards body, a regulator, an RFC, vendor docs), never a guessed URL. A future research step could ground the links. |
| **The story / 90-sec arc** | generated | `Resume` / career-profile sources (summary, timeline, positions, leadership) → one throughline tuned to this posting |
| **Company-specific hooks** | generated + researched | web research on the company (awards, history, culture) matched against résumé highlights; 4–6 candidate hooks, ranked |
| **Warm-intro / referral play** | generated | `Contact` linked to the posting (referral) + résumé overlap with that contact's shared history |
| **Likely questions** | generated | posting requirements + `QuestionArchetype` / `InterviewQuestion` history + known résumé soft spots (title delta, gaps, contract stints) |
| **Questions to ask them** | generated | posting ambiguities + comp/leveling probe + culture-criterion probe (per the culture-fit standing criterion) |
| **Night-before checklist** | template + derived | fixed skeleton; fills in scheduled time, ATS links, referral name, the persona/résumé-version reminder |

**Inputs the generator needs:** the `JobPosting` (+ company, + raw ATS text if datalake has
it), the applicable `Resume` / career-profile sources, the linked referral `Contact` if any,
the posting's `InterviewQuestion` / archetype history, web research on the company, and the
standing job-search criteria (comp floor, culture-over-comp, US-only, role-positioning).

**Storage.** One prep pack per `InterviewSession` (which already `belongs_to :job_posting`).
Regenerable — keep the last generated version and let Mike edit in place; edits survive
regeneration or regeneration is explicit-overwrite. Rendered on the job posting show page in
the existing interview-notes section.

**Boundaries.** Generation is a read + LLM call (local-first per the orchestration layer,
hosted fallback allowed — this is Mike's own career data, not scraped hostile input). No
outbound action. Mike reviews/edits before it's "his." Same bounded-agency rule as the rest
of the system.
