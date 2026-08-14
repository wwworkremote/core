# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Models" do
  let!(:model) { create(:model) }

  before do
    driven_by(:rack_test)
  end

  describe "GET /admin/models" do
    it "displays the model registry" do
      visit admin_models_path
      expect(page).to have_text("AI Models")
      expect(page).to have_css("tr")
    end
  end

  describe "GET /admin/models/:id" do
    it "displays the model details" do
      visit admin_model_path(model)
      expect(page).to have_text(model.model_id)
    end
  end
end
