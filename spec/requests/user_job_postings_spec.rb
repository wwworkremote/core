require 'rails_helper'

RSpec.describe "UserJobPostings", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/user_job_postings/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/user_job_postings/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/user_job_postings/destroy"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /index" do
    it "returns http success" do
      get "/user_job_postings/index"
      expect(response).to have_http_status(:success)
    end
  end

end
