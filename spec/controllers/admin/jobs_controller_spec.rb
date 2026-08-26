# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::JobsController do
  let(:admin) { User.create!(email: "admin@example.com", password: "password") }

  before do
    # Mock authentication logic since it's a controller spec
    allow(controller).to receive_messages(authenticate_admin: true, current_user: admin)
  end

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "assigns scheduler_info" do
      get :index
      expect(assigns(:scheduler_info)).to be_present
    end

    it "assigns job_runs" do
      get :index
      expect(assigns(:job_runs)).to be_a(ActiveRecord::Relation)
    end
  end

  describe "POST #trigger" do
    it "triggers a job and redirects" do
      # fetch_all_jobs exists in recurring.yml
      post :trigger, params: { task_id: "fetch_all_jobs" }
      expect(response).to redirect_to(admin_jobs_path)
      expect(flash[:notice]).to be_present
    end

    it "rejects unauthorized task IDs" do
      post :trigger, params: { task_id: "rm_rf_slash" }
      expect(response).to redirect_to(admin_jobs_path)
      expect(flash[:alert]).to include("Unauthorized")
    end
  end

  describe "POST #prune" do
    it "prunes dead processes and redirects" do
      post :prune
      expect(response).to redirect_to(admin_jobs_path)
      expect(flash[:notice]).to include("Pruned")
    end
  end
end
