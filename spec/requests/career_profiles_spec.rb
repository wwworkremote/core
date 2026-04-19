require 'rails_helper'

RSpec.describe "CareerProfiles", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/career_profiles/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/career_profiles/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/career_profiles/update"
      expect(response).to have_http_status(:success)
    end
  end

end
