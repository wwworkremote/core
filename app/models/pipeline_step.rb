# frozen_string_literal: true

# == Schema Information
#
# Table name: pipeline_steps
#
#  id             :bigint           not null, primary key
#  link           :string
#  note           :text
#  notes          :text
#  reason_tags    :jsonb            not null
#  status         :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  job_posting_id :bigint           not null
#  user_id        :bigint
#
# Indexes
#
#  index_pipeline_steps_on_job_posting_id  (job_posting_id)
#  index_pipeline_steps_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (user_id => users.id)
#
class PipelineStep < ApplicationRecord
  belongs_to :job_posting
  belongs_to :user, optional: true

  has_many_attached :artifacts

  # Optional link and note fields to capture pipeline activity
  # Status: favorited, applied, interview, offered, archived, noted

  validates :status, presence: true

  # `link` is rendered with link_to on the posting timeline, and every writer
  # feeds it outside-the-app input -- the admin note form, and now the Chrome
  # extension posting the ATS page URL. Without a scheme check a `javascript:`
  # value becomes a clickable payload in the user's own UI.
  # \z anchors the end too -- without it, "https://good.com\nCRLF-injected-junk"
  # still matched (only the start was anchored), silently passing anything
  # appended after a valid-looking prefix into an outside-writer field.
  validates :link, format: { with: %r{\Ahttps?://\S+\z}i, message: "must be an http(s) URL" }, allow_blank: true
end
