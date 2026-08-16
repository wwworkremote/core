# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::Sources" do
  describe "GET /api/v0/sources" do
    it "returns sources newest first" do
      older = create(:source)
      newer = create(:source)

      get api_v0_sources_path

      expect(response).to be_successful
      ids = response.parsed_body.pluck("id")
      expect(ids).to eq([newer.id, older.id])
    end
  end

  describe "GET /api/v0/sources/:id" do
    it "returns the source as json" do
      source = create(:source)

      get api_v0_source_path(source)

      expect(response).to be_successful
      expect(response.parsed_body["id"]).to eq(source.id)
    end
  end
end
