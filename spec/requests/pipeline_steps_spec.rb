require 'rails_helper'

RSpec.describe "PipelineSteps", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/pipeline_steps/create"
      expect(response).to have_http_status(:success)
    end
  end

end
