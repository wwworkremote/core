# frozen_string_literal: true

class CompanyPipelineStepsController < ApplicationController
  def create
    @company = Company.find(params[:company_id])
    
    if params[:status].present?
      @company.send("#{params[:status]}!") if @company.respond_to?("#{params[:status]}!")
      @company.company_pipeline_steps.create!(status: params[:status], note: "Status changed to #{params[:status]}")
    elsif params[:note].present?
      @company.add_pipeline_note(params[:note], link: params[:link])
    end

    redirect_to admin_company_path(@company), notice: "Activity logged."
  end
end
