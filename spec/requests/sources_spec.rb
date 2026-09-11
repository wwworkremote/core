# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sources" do
  let!(:source) { create(:job_boards_source, name: "Greenhouse", slug: "greenhouse") }

  describe "GET /sources" do
    it "lists searchable sources" do
      create(:job_boards_source, name: "Lever", slug: "lever")

      get sources_path, params: { q: "Green" }

      expect(response).to be_successful
      expect(response.body).to include("Greenhouse")
      expect(response.body).not_to include("Lever")
    end
  end

  describe "GET /sources/:id" do
    it "shows a source" do
      get source_path(source)

      expect(response).to be_successful
      expect(response.body).to include("Greenhouse", "greenhouse")
    end
  end
end
