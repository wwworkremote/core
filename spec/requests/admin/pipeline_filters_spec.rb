# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::PipelineFilters" do
  describe "GET /admin/pipeline_filters" do
    it "renders the static filter/routing overview" do
      get admin_pipeline_filters_path

      expect(response).to be_successful
      expect(response.body).to include(RoleFamily::FAMILIES.keys.first.to_s.humanize)
      expect(response.body).to include(Company::BIG_TECH_NAMES.first)
    end
  end
end
