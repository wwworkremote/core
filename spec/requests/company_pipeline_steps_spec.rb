require 'rails_helper'

RSpec.describe "CompanyPipelineSteps", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/company_pipeline_steps/create"
      expect(response).to have_http_status(:success)
    end
  end

end
