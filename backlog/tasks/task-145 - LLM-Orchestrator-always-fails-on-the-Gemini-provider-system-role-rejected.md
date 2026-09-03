---
id: TASK-145
title: 'LLM::Orchestrator always fails on the Gemini provider (system role rejected)'
status: To Do
assignee: []
created_date: '2026-09-02 17:22'
labels:
  - llm
  - bug
dependencies: []
references:
  - config/models.yml
  - app/services/llm/orchestrator.rb
  - app/services/llm/orchestrator/streamer.rb
priority: high
type: bug
ordinal: 161000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Any LLM::Orchestrator.call routed to a Gemini model fails with:

  "Model execution failed: Role 'system' is not supported. Please use a valid role: MODEL, USER."

Repro (rails runner):
  LLM::Orchestrator.call(untrusted_text: "hi", system_rules: "terse", task_instructions: "answer",
                         model: Model.find_by(model_id: "gemini-3.7-flash"))
  => {success: false, error: "Model execution failed: Role 'system' is not supported..."}

Fails even with system_rules: nil, because LLM::Orchestrator#default_system_rules always supplies
"You are a helpful assistant." and #seed_chat_messages then persists a role:"system" LLMMessage.
LLM::Orchestrator::Streamer#llm_messages replays those roles verbatim to the provider via a direct
provider_class.new(RubyLLM.config).complete(messages) call, bypassing whatever RubyLLM::Chat would
normally do to map a system message to Gemini's system_instruction.

Impact: config/models.yml has pointed defaults.answer_generation at "gemini-3.7-flash" since
2026-08-24, so every AI-path screening-answer generation has been silently failing since then
(nothing reads defaults.fallback, so it does not degrade to local -- it just returns the error).
Also blocks pointing defaults.interview_prep (TASK-144) at a hosted model, which is the documented
upgrade path when local prose quality is insufficient.

Local (openai-compatible, openai_use_system_role = true) and the direct-model paths are unaffected;
this is Gemini-provider-specific.

Found while dogfooding TASK-144 -- the local 7B model produced a usable but generic pack and the
natural next step (hosted model) hit this wall.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 LLM::Orchestrator.call succeeds against a gemini-* model with system_rules present (returns {success: true, output: ...})
- [ ] #2 The system prompt content actually reaches the Gemini model (as system_instruction or folded into the first user turn) -- not silently dropped
- [ ] #3 Local and Anthropic/OpenAI-compatible paths still pass their existing orchestrator specs
- [ ] #4 A spec exercises the Gemini provider path (stubbed at the provider boundary) so this regression is caught
- [ ] #5 config/models.yml defaults.answer_generation on gemini-3.7-flash produces a real screening answer again
<!-- AC:END -->
