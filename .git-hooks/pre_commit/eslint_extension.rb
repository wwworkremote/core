# frozen_string_literal: true

# Lints extension/**/*.js with ESLint (see eslint.config.js). See bin/lint_extension.
class Overcommit::Hook::PreCommit::EslintExtension < Overcommit::Hook::PreCommit::Base
  def run
    result = execute(%w[bin/lint_extension])
    return :pass if result.success?

    [:fail, result.stdout + result.stderr]
  end
end
