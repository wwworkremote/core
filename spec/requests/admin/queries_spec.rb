# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Queries" do
  let!(:source) { create(:job_boards_source) }
  let!(:query) { create(:job_boards_query, job_boards_source: source) }

  describe "GET /admin/queries" do
    it "returns a success response" do
      get admin_queries_path
      expect(response).to be_successful
    end
  end

  describe "GET /admin/queries/:id" do
    it "returns a success response" do
      get admin_query_path(query)
      expect(response).to be_successful
    end
  end
end
