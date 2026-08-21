# frozen_string_literal: true

# == Schema Information
#
# Table name: work_experiences
#
#  id                :bigint           not null, primary key
#  action            :text
#  company_name      :string
#  context           :text
#  description       :text
#  embedding         :vector(768)
#  employment_type   :string
#  end_date          :date
#  impact            :text
#  location          :string
#  scope             :jsonb
#  start_date        :date
#  summary           :text
#  title             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  career_profile_id :bigint           not null
#  external_id       :string
#
# Indexes
#
#  index_work_experiences_on_career_profile_id  (career_profile_id)
#  index_work_experiences_on_external_id        (external_id)
#
# Foreign Keys
#
#  fk_rails_...  (career_profile_id => career_profiles.id)
#
class WorkExperience < ApplicationRecord
  belongs_to :career_profile
  has_many :experience_highlights, dependent: :destroy

  has_neighbors :embedding

  EMBEDDABLE_ATTRIBUTES = %w[title company_name employment_type summary impact description].freeze

  after_commit :enqueue_embedding, on: %i[create update]

  # The text an embedding is built from, and the text a prompt renders. Kept
  # in one place so what gets searched and what gets shown can't drift apart
  # -- a match on words the model never sees would be worse than no match.
  def embeddable_text
    [title, company_name, employment_type, summary, impact, description].compact_blank.join(". ")
  end

  private

  # Re-embeds only when the text an embedding is built from actually changed.
  # That's also what stops a loop: the job writes `embedding`, which fires
  # this callback again, but `embedding` isn't an embeddable attribute so the
  # second pass enqueues nothing.
  def enqueue_embedding
    return unless previous_changes.keys.intersect?(EMBEDDABLE_ATTRIBUTES)

    Resume::WorkExperienceEmbeddingJob.perform_later(id)
  end
end
