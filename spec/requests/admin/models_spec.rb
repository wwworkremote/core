# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Models" do
  let!(:model) { create(:model, name: "Test Model") }

  describe "GET /admin/models" do
    it "returns a success response" do
      get admin_models_path
      expect(response).to be_successful
      expect(response.body).to include("Test Model")
    end
  end

  describe "GET /admin/models/:id" do
    it "returns a success response" do
      get admin_model_path(model)
      expect(response).to be_successful
      expect(response.body).to include("llama3.2:latest")
    end
  end
end
