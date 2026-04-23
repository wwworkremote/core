# frozen_string_literal: true

class OutboundLinksController < ApplicationController
  def show
    # Security: Only redirect to URLs stored in our database for a specific job posting
    job_posting = JobPosting.find_by(id: params[:job_posting_id])

    if job_posting&.target_url.present?
      ahoy.track 'Clicked Outbound Link', job_posting_id: job_posting.id, url: job_posting.target_url
      redirect_to job_posting.target_url, allow_other_host: true
    else
      # If no posting ID, check if the URL exists in any of our records as a secondary verification
      verified_url = JobPosting.where(target_url: params[:url]).limit(1).pick(:target_url)

      if verified_url.present?
        ahoy.track 'Clicked Outbound Link', url: verified_url
        redirect_to verified_url, allow_other_host: true
      else
        Rails.logger.warn "SECURITY: Blocked attempt to use OutboundLinksController for open redirect to: #{params[:url]}"
        redirect_back_or_to(root_path, alert: 'Security Exception: Invalid destination.')
      end
    end
  end
end
