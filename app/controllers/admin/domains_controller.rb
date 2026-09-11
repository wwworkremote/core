# frozen_string_literal: true

class Admin::DomainsController < Admin::ApplicationController
  def index
    @domains = Domain.order(:name).page(params[:page]).per(50)
  end

  def show
    @domain = Domain.find(params.expect(:id))
    @job_postings = @domain.job_postings.recent.page(params[:job_page]).per(20)
  end

  def destroy
    @domain = Domain.find(params.expect(:id))
    @domain.destroy
    redirect_to admin_domains_path, notice: "Domain was successfully deleted."
  end
end
