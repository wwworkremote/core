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
#  skills            :text
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

  EMBEDDABLE_ATTRIBUTES = %w[title company_name employment_type summary impact description skills].freeze

  after_commit :enqueue_embedding, on: %i[create update]

  # The text an embedding is built from, and the text a prompt renders. Kept
  # in one place so what gets searched and what gets shown can't drift apart
  # -- a match on words the model never sees would be worse than no match.
  #
  # Highlights and skills were both missing here while being imported and
  # stored, which made this the narrowest point in the whole retrieval path.
  # Highlights are 10,337 characters across the corpus -- 40% of the total,
  # and the specific 40%: the bullets naming what was actually built. Skills
  # carry the technology vocabulary that appears nowhere else. Without them a
  # question about C# or pgvector had no retrievable evidence behind it, and
  # every entry looked alike to cosine distance, which is exactly what the
  # flat 0.56-0.63 spread over 24 experiences was showing.
  def embeddable_text
    embeddable_parts.compact_blank.join(". ")
  end

  private

  # Skills sits third, not last, because the embed server truncates at 1500
  # characters and 5 of 28 experiences are longer than that. Last position put
  # the skills list -- the one field whose terms appear nowhere else on the
  # record -- inside the part that gets cut. Identity and vocabulary first,
  # then prose, so truncation costs the most redundant text rather than the
  # least redundant.
  def embeddable_parts
    [title, company_name, skills, employment_type, summary, impact, description,
     *experience_highlights.map(&:text)]
  end

  # Re-embeds only when the text an embedding is built from actually changed.
  # That's also what stops a loop: the job writes `embedding`, which fires
  # this callback again, but `embedding` isn't an embeddable attribute so the
  # second pass enqueues nothing.
  def enqueue_embedding
    return unless previous_changes.keys.intersect?(EMBEDDABLE_ATTRIBUTES)

    Resume::WorkExperienceEmbeddingJob.perform_later(id)
  end
end
