# frozen_string_literal: true

class Admin::SkillsController < Admin::ApplicationController
  def index
    @skills = Skill.order(:name).page(params[:page])
  end

  def show
    @skill = Skill.find(params.expect(:id))
    @nearest_skills = VectorIntelligence.rank(source: @skill, target_class: Skill, limit: 6).where.not(id: @skill.id)
  end

  def new
    @skill = Skill.new
  end

  def edit
    @skill = Skill.find(params.expect(:id))
  end

  def create
    @skill = Skill.new(skill_params)
    @skill.save ? redirect_on_skill_created : render(:new, status: :unprocessable_content)
  end

  def update
    @skill = Skill.find(params.expect(:id))
    @skill.update(skill_params) ? redirect_on_skill_updated : render(:edit, status: :unprocessable_content)
  end

  def destroy
    @skill = Skill.find(params.expect(:id))
    @skill.destroy
    redirect_to admin_skills_path, notice: "Skill deleted."
  end

  private

  def redirect_on_skill_created
    redirect_to admin_skills_path, notice: "Skill created."
  end

  def redirect_on_skill_updated
    redirect_to admin_skill_path(@skill), notice: "Skill updated."
  end

  def skill_params
    params.expect(skill: %i[name category description])
  end
end
