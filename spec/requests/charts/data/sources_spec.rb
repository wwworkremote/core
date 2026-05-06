# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Charts::Data::Sources" do
  describe "GET /charts/data/sources" do
    it "returns JSON data for source registration velocity" do
      create(:source, signature: "s1")
      get charts_data_sources_path
      expect(response).to be_successful
      data = response.parsed_body
      expect(data.values.sum).to eq(1)
    end
  end
end
