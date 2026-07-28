# frozen_string_literal: true

class ResumesController < ApplicationController
  before_action :set_resume, only: %i[show edit update destroy fork diff export]

  def index
    return import_resume if params[:import_url].present?

    @resumes = current_user.resumes.order(name: :asc, version: :desc)
  end

  def show
    @parent = @resume.parent
    @children = @resume.children
  end

  def new
    @resume = current_user.resumes.new
  end

  def edit; end

  def create
    @resume = current_user.resumes.new(processed_params)
    respond_with_resume(@resume.save, resumes_path, "Resume created.", :new)
  end

  def update
    respond_with_resume(@resume.update(processed_params), resume_path(@resume), "Resume updated.", :edit)
  end

  def destroy
    @resume.destroy
    redirect_to resumes_path, notice: "Resume deleted."
  end

  def fork
    @forked = ResumeManager.fork(@resume, new_name: params[:new_name])
    redirect_to resume_path(@forked), notice: "Resume forked successfully."
  end

  def diff
    @resume_a = @resume
    @resume_b = current_user.resumes.find(params.expect(:other_id))
    @diff = ResumeManager.diff(@resume_a, @resume_b)
  end

  def export
    format = params[:format] || :markdown
    content = ResumeManager.export(@resume, format: format)

    send_data content, filename: "resume_v#{@resume.version}.#{format}", type: "text/plain"
  end

  private

  def set_resume
    @resume = current_user.resumes.find(params.expect(:id))
  end

  def import_resume
    @imported = ResumeManager.import(current_user, url: params[:import_url])
    redirect_to resume_path(@imported), notice: "Resume imported from #{params[:import_url]}"
  end

  def respond_with_resume(success, redirect_target, notice, failure_view)
    if success
      redirect_to redirect_target, notice: notice
    else
      render failure_view, status: :unprocessable_content
    end
  end

  def processed_params
    attrs = resume_params.to_h
    attrs[:content] = parsed_content(attrs[:content]) if attrs[:content].is_a?(String)
    attrs
  end

  def parsed_content(content)
    JSON.parse(content)
  rescue JSON::ParserError
    content
  end

  def resume_params
    params.expect(resume: %i[name version status content imported_from_url])
  end
end
