# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Models" do
  describe "GET /models" do
    it "lists the available chat models" do
      create(:model, name: "Llama 3.2 Local")

      get models_path

      expect(response).to be_successful
      expect(response.body).to include("Llama 3.2 Local")
    end
  end

  describe "GET /models/:id" do
    it "shows the model" do
      model = create(:model)

      get model_path(model)

      expect(response).to be_successful
      expect(response.body).to include(model.model_id)
    end
  end

  describe "POST /models/refresh" do
    it "refreshes the registry and redirects with a notice" do
      allow(Model).to receive(:refresh!)

      post refresh_models_path

      expect(Model).to have_received(:refresh!)
      expect(response).to redirect_to(models_path)
      expect(flash[:notice]).to eq("Models refreshed successfully")
    end
  end
end
