# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Companies" do
  describe "GET /api/companies/search" do
    it "returns fuzzy-matching companies" do
      create(:company, name: "Acme Corporation")
      create(:company, name: "Globex Inc")

      get api_companies_search_path, params: { q: "Acme Corp" }

      expect(response).to be_successful
      assert_schema_conform(200)
      names = response.parsed_body.pluck("name")
      expect(names).to include("Acme Corporation")
      expect(names).not_to include("Globex Inc")
    end

    it "returns an empty array for no matches" do
      get api_companies_search_path, params: { q: "no-such-company-xyz" }

      expect(response).to be_successful
      assert_schema_conform(200)
      expect(response.parsed_body).to eq([])
    end
  end
end
