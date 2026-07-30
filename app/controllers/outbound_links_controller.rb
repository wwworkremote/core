# frozen_string_literal: true

class OutboundLinksController < ApplicationController
  def show
    # Security: Only redirect to URLs stored in our database for a specific job posting
    job_posting = JobPosting.find_by(id: params[:job_posting_id])
    return redirect_to_verified_url if job_posting&.target_url.blank?

    redirect_to_target(job_posting.target_url, job_posting_id: job_posting.id)
  end

  private

  # If no posting ID, check if the URL exists in any of our records as a secondary verification
  def redirect_to_verified_url
    verified_url = JobPosting.where(target_url: params[:url]).limit(1).pick(:target_url)
    return block_open_redirect if verified_url.blank?

    redirect_to_target(verified_url)
  end

  def redirect_to_target(url, job_posting_id: nil)
    ahoy.track "Clicked Outbound Link", { url: url, job_posting_id: job_posting_id }.compact
    redirect_to url, allow_other_host: true
  end

  def block_open_redirect
    Rails.logger.warn "SECURITY: Blocked attempt to use OutboundLinksController for open redirect " \
                      "to: #{params[:url]}"
    redirect_back_or_to(root_path, alert: "Security Exception: Invalid destination.")
  end
end
