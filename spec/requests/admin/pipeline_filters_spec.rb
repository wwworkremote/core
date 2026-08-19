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

    it "shows the configured preferred countries (TASK-69.3)" do
      create(:user, preferred_countries: ["US"])

      get admin_pipeline_filters_path

      expect(response.body).to include("US")
      expect(response.body).not_to include("filter is inert")
    end

    it "flags an empty preferred_countries list as inert" do
      User.update_all(preferred_countries: []) # rubocop:disable Rails/SkipsModelValidations

      get admin_pipeline_filters_path

      expect(response.body).to include("filter is inert")
    end
  end
end
