# frozen_string_literal: true

class ResumeManager::ForkService
  def initialize(resume)
    @resume = resume
  end

  def call(new_name: nil)
    name = new_name || @resume.name
    version = calculate_next_version(name)

    @resume.user.resumes.create!(
      name: name,
      version: version,
      parent_id: @resume.id,
      content: @resume.content,
      status: :inactive,
      skills: @resume.skills
    )
  end

  private

  def calculate_next_version(name)
    latest_version = @resume.user.resumes.where(name: name).maximum(:version) || 0
    latest_version + 1
  end
end
