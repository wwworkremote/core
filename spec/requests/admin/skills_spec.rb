# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Skills" do
  let!(:skill) { create(:skill, name: "Ruby") }

  describe "GET /admin/skills" do
    it "lists skills" do
      get admin_skills_path
      expect(response).to be_successful
      expect(response.body).to include("Ruby")
    end
  end

  describe "GET /admin/skills/:id" do
    it "shows the skill and its nearest neighbors, excluding itself" do
      other = create(:skill, name: "Rails")
      allow(VectorIntelligence).to receive(:rank)
        .with(source: skill, target_class: Skill, limit: 6)
        .and_return(Skill.where(id: [skill.id, other.id]))

      get admin_skill_path(skill)

      expect(response).to be_successful
      expect(response.body).to include("Rails")
    end
  end

  describe "GET /admin/skills/new" do
    it "renders the new form" do
      get new_admin_skill_path
      expect(response).to be_successful
    end
  end

  describe "GET /admin/skills/:id/edit" do
    it "renders the edit form" do
      get edit_admin_skill_path(skill)
      expect(response).to be_successful
    end
  end

  describe "POST /admin/skills" do
    it "creates the skill and redirects with a notice" do
      expect {
        post admin_skills_path, params: { skill: { name: "GraphQL", category: "Backend" } }
      }.to change(Skill, :count).by(1)

      expect(response).to redirect_to(admin_skills_path)
      expect(flash[:notice]).to eq("Skill created.")
    end

    it "re-renders the form with an unprocessable status when invalid" do
      post admin_skills_path, params: { skill: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/skills/:id" do
    it "updates the skill and redirects with a notice" do
      patch admin_skill_path(skill), params: { skill: { name: "Ruby on Rails" } }

      expect(skill.reload.name).to eq("Ruby on Rails")
      expect(response).to redirect_to(admin_skill_path(skill))
      expect(flash[:notice]).to eq("Skill updated.")
    end

    it "re-renders the form with an unprocessable status when invalid" do
      patch admin_skill_path(skill), params: { skill: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /admin/skills/:id" do
    it "destroys the skill and redirects with a notice" do
      delete admin_skill_path(skill)

      expect(Skill.exists?(skill.id)).to be false
      expect(response).to redirect_to(admin_skills_path)
      expect(flash[:notice]).to eq("Skill deleted.")
    end
  end
end
