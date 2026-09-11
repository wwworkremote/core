# frozen_string_literal: true

class ResumeManager::ForkService
  def initialize(resume)
    @resume = resume
  end

  def call(new_name: nil)
    name = new_name || @resume.name
    create_fork(name, calculate_next_version(name))
  end

  private

  # One cohesive create! call -- splitting it further would obscure it,
  # not simplify it.
  # rubocop:disable Metrics/MethodLength
  def create_fork(name, version)
    @resume.user.resumes.create!(
      name: name,
      version: version,
      parent_id: @resume.id,
      content: @resume.content,
      status: :inactive,
      skills: @resume.skills
    )
  end
  # rubocop:enable Metrics/MethodLength

  def calculate_next_version(name)
    latest_version = @resume.user.resumes.where(name: name).maximum(:version) || 0
    latest_version + 1
  end
end
