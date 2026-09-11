# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::PipelinePrompts" do
  let(:valid_params) {
    { key: "job_boards_categorizer", name: "Categorizer", stage: "categorization", body: "Classify: <%= title %>" }
  }
  let!(:prompt) { PipelinePrompt.create!(valid_params.merge(key: "existing_key")) }

  describe "GET /admin/pipeline_prompts" do
    it "lists prompts" do
      get admin_pipeline_prompts_path
      expect(response).to be_successful
      expect(response.body).to include(prompt.name)
    end
  end

  describe "GET /admin/pipeline_prompts/:id" do
    it "shows the prompt" do
      get admin_pipeline_prompt_path(prompt)
      expect(response).to be_successful
    end
  end

  describe "GET /admin/pipeline_prompts/new" do
    it "renders the new form" do
      get new_admin_pipeline_prompt_path
      expect(response).to be_successful
    end
  end

  describe "GET /admin/pipeline_prompts/:id/edit" do
    it "renders the edit form" do
      get edit_admin_pipeline_prompt_path(prompt)
      expect(response).to be_successful
    end
  end

  describe "POST /admin/pipeline_prompts" do
    it "creates the prompt and redirects with a notice" do
      expect {
        post admin_pipeline_prompts_path, params: { pipeline_prompt: valid_params }
      }.to change(PipelinePrompt, :count).by(1)

      expect(response).to redirect_to(admin_pipeline_prompts_path)
      expect(flash[:notice]).to eq("Prompt created.")
    end

    it "re-renders the form with an unprocessable status when invalid" do
      post admin_pipeline_prompts_path, params: { pipeline_prompt: valid_params.merge(key: "") }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/pipeline_prompts/:id" do
    it "updates the prompt and redirects with a notice" do
      patch admin_pipeline_prompt_path(prompt), params: { pipeline_prompt: { name: "Renamed" } }

      expect(prompt.reload.name).to eq("Renamed")
      expect(response).to redirect_to(admin_pipeline_prompt_path(prompt))
      expect(flash[:notice]).to eq("Prompt updated.")
    end

    it "re-renders the form with an unprocessable status when invalid" do
      patch admin_pipeline_prompt_path(prompt), params: { pipeline_prompt: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /admin/pipeline_prompts/:id" do
    it "destroys the prompt and redirects with a notice" do
      delete admin_pipeline_prompt_path(prompt)

      expect(PipelinePrompt.exists?(prompt.id)).to be false
      expect(response).to redirect_to(admin_pipeline_prompts_path)
      expect(flash[:notice]).to eq("Prompt deleted.")
    end
  end
end
