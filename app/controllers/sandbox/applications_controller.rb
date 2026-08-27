# frozen_string_literal: true

# The sandbox provider's fake submit endpoint. ats_application_id is minted
# only here, at confirmation -- job_post_id was already minted at page load
# in Sandbox::PostingsController#show -- so the fixture exercises
# Scenarios::HandshakeCheck's `required` vs `required_after_submit`
# distinction for real, not just the easy always-present case. See
# docs/architecture/sandbox-provider.md.
class Sandbox::ApplicationsController < Sandbox::ApplicationController
  def create
    @job_post_id = params[:job_post_id]
    @ats_application_id = SecureRandom.hex(8)
  end
end
