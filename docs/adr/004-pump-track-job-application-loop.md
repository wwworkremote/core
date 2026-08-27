# ADR 004: Model the Job Search as a Pump Track

## Status
Accepted

## Context

The job-posting-to-application process is not a linear wizard with a terminal
state. Provider-specific subflows vary, but they mostly occupy the same
recurring phases: a request enters the system, the system resolves it into an
outcome, that outcome is shaped into a response, and the actor decides whether
to begin another cycle.

The useful mental model is a pump track. The actor and the system ride
together; progress depends on timing, feedback, accumulated momentum, and
knowing when to push, coast, or stop. A job application is one lap. Getting
hired changes the terrain and begins a new game rather than ending it.

## Decision

We will model the pipeline as four recurring phases:

1. **Intake** — the actor makes a request or selects the next opportunity.
2. **Resolution** — the system gathers, evaluates, and transforms information
   into an outcome.
3. **Response Construction** — the system packages that outcome into a
   legible, actionable response.
4. **Reorientation** — the actor reviews the response, acts, learns, and either
   starts another lap or stops.

Provider-specific workflows are variations inside these phases, not separate
top-level pipeline models unless they introduce genuinely different behavior.

The cycle is represented as:

`C_(n+1) = ActorDecision(Present(Construct(Resolve(Intake(C_n)))))`

The actor decision returns either a new cycle state or a terminal stop state.
The system must preserve enough context across the transition for the next lap
to benefit from the previous one.

## Consequences

- Pipeline features should identify which phase they serve and what state they
  hand to the next phase.
- Application, interview, offer, and employment outcomes are transitions in
  the loop, not assumptions that the loop is over.
- Feedback, history, and accumulated learning are first-class product value:
  they increase momentum for later laps.
- The UI should make the current phase, next move, and available stop/continue
  choice legible to Mike.
- A provider-specific subflow earns its own module when its behavior differs,
  while the shared phase model remains stable.
- A complete lap is recorded as a supervised session when the system is being
  taught intent; see ADR 005.

## Rejected Alternatives

- **Linear application wizard:** hides waiting, feedback, retries, and the
  actor's decisions between system operations.
- **Pure sinusoidal process model:** captures the rise and fall of activity but
  suggests passive repetition; “pump track” better captures active momentum
  and changing terrain.
