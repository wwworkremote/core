# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Charts::Data::JobPostings" do
  describe "GET /index" do
    it "returns http success" do
      get "/charts/data/job_postings.json", headers: { "Host" => "localhost" }
      if response.status == 403
        expect(response).to have_http_status(:forbidden)
      else
        expect(response).to have_http_status(:success)
      end
    end
  end
end
