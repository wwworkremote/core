# frozen_string_literal: true

class OutboundLinksController < ApplicationController
  def show
    url = params[:url]
    job_posting_id = params[:job_posting_id]

    if url.present?
      # Validate URL is safe before redirecting
      uri = URI.parse(url)
      if %w[http https].include?(uri.scheme)
        ahoy.track "Clicked Outbound Link", job_posting_id: job_posting_id, url: url
        redirect_to url, allow_other_host: true
      else
        redirect_back fallback_location: root_path, alert: "Invalid destination URL."
      end
    else
      redirect_back fallback_location: root_path, alert: "No destination URL provided."
    end
  rescue URI::InvalidURIError
    redirect_back fallback_location: root_path, alert: "Invalid destination URL."
  end
end
