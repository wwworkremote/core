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
    if @skill.save
      redirect_to admin_skills_path, notice: "Skill created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @skill = Skill.find(params.expect(:id))
    if @skill.update(skill_params)
      redirect_to admin_skill_path(@skill), notice: "Skill updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @skill = Skill.find(params.expect(:id))
    @skill.destroy
    redirect_to admin_skills_path, notice: "Skill deleted."
  end

  private

  def skill_params
    params.expect(skill: %i[name category description])
  end
end
