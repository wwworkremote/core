# frozen_string_literal: true

# Validates that .claude/skills/**/SKILL.md and .claude/agents/*.md are
# self-describing (required frontmatter, versioned, referenced scripts
# exist and parse). See bin/verify_claude_assets.
class Overcommit::Hook::PreCommit::ClaudeAssets < Overcommit::Hook::PreCommit::Base
  def run
    result = execute(%w[bin/verify_claude_assets])
    return :pass if result.success?

    [:fail, result.stdout]
  end
end
