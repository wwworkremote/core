# frozen_string_literal: true

class ResumesController < ApplicationController
  def index
    if params[:import_url].present?
      @imported = ResumeManager.import(current_user, url: params[:import_url])
      redirect_to resume_path(@imported), notice: "Resume imported from #{params[:import_url]}" and return
    end
    @resumes = current_user.resumes.order(name: :asc, version: :desc)
  end

  def show
    @resume = current_user.resumes.find(params.expect(:id))
    @parent = @resume.parent
    @children = @resume.children
  end

  def new
    @resume = current_user.resumes.new
  end

  def edit
    @resume = current_user.resumes.find(params.expect(:id))
  end

  def create
    @resume = current_user.resumes.new(processed_params)
    if @resume.save
      redirect_to resumes_path, notice: "Resume created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @resume = current_user.resumes.find(params.expect(:id))
    if @resume.update(processed_params)
      redirect_to resume_path(@resume), notice: "Resume updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @resume = current_user.resumes.find(params.expect(:id))
    @resume.destroy
    redirect_to resumes_path, notice: "Resume deleted."
  end

  def fork
    @resume = current_user.resumes.find(params.expect(:id))
    @forked = ResumeManager.fork(@resume, new_name: params[:new_name])
    redirect_to resume_path(@forked), notice: "Resume forked successfully."
  end

  def diff
    @resume_a = current_user.resumes.find(params.expect(:id))
    @resume_b = current_user.resumes.find(params.expect(:other_id))
    @diff = ResumeManager.diff(@resume_a, @resume_b)
  end

  def export
    @resume = current_user.resumes.find(params.expect(:id))
    format = params[:format] || :markdown
    content = ResumeManager.export(@resume, format: format)

    send_data content, filename: "resume_v#{@resume.version}.#{format}", type: "text/plain"
  end

  private

  def processed_params
    p = resume_params.to_h
    if p[:content].is_a?(String)
      begin
        p[:content] = JSON.parse(p[:content])
      rescue JSON::ParserError
        # Fallback if invalid JSON
      end
    end
    p
  end

  def resume_params
    params.expect(resume: %i[name version status content imported_from_url])
  end
end
