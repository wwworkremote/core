# frozen_string_literal: true

# A fake Greenhouse-shaped job posting page. Mirrors the real DOM shape
# TASK-78's extension listener already targets (`#application-form`,
# `question_<n>` fields, `#demographic-section`) with placeholder job/company
# copy -- never a real employer's real posting. See
# docs/architecture/sandbox-provider.md.
class Sandbox::PostingsController < Sandbox::ApplicationController
  # Minted fresh on every page load, matching SIGNATURE_EXPECTATIONS's
  # `required` for job_post_id (Scenarios::HandshakeCheck) -- present from
  # the moment the page renders, unlike ats_application_id which only
  # exists after a submit reaches the confirmation step.
  def show
    # Numeric, like a real Greenhouse job post id -- so the capture patterns
    # in Scenarios::Capture::PATTERNS["greenhouse"] (which expect \d+) match it
    # whether it arrives via the posting URL or the form's hidden field.
    @job_post_id = SecureRandom.random_number(10**10).to_s
  end
end
