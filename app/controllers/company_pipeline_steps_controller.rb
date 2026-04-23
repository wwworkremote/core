# frozen_string_literal: true

class CompanyPipelineStepsController < ApplicationController
  def create
    @company = Company.find(params[:company_id])

    if params[:status].present?
      # Whitelist AASM events to prevent dangerous send
      allowed_events = %w[favorite archive]
      if allowed_events.include?(params[:status])
        @company.send("#{params[:status]}!")
        @company.company_pipeline_steps.create!(status: params[:status], note: "Status changed to #{params[:status]}")
      end
    elsif params[:note].present?
      @company.add_pipeline_note(params[:note], link: params[:link])
    end

    redirect_to admin_company_path(@company), notice: 'Activity logged.'
  end
end
