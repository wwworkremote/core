# frozen_string_literal: true

class Admin::PipelinePromptsController < Admin::ApplicationController
  before_action :set_pipeline_prompt, only: %i[show edit update destroy]

  def index
    @pipeline_prompts = PipelinePrompt.order(:stage, :name).page(params[:page])
  end

  def show; end

  def new
    @pipeline_prompt = PipelinePrompt.new
  end

  def edit; end

  def create
    @pipeline_prompt = PipelinePrompt.new(pipeline_prompt_params)
    @pipeline_prompt.save ? redirect_on_created : render(:new, status: :unprocessable_content)
  end

  def update
    @pipeline_prompt.update(pipeline_prompt_params) ? redirect_updated : render(:edit, status: :unprocessable_content)
  end

  def destroy
    @pipeline_prompt.destroy
    redirect_to admin_pipeline_prompts_path, notice: "Prompt deleted."
  end

  private

  def set_pipeline_prompt
    @pipeline_prompt = PipelinePrompt.find(params.expect(:id))
  end

  def redirect_on_created
    redirect_to admin_pipeline_prompts_path, notice: "Prompt created."
  end

  def redirect_updated
    redirect_to admin_pipeline_prompt_path(@pipeline_prompt), notice: "Prompt updated."
  end

  def pipeline_prompt_params
    params.expect(pipeline_prompt: %i[key name stage body description active])
  end
end
