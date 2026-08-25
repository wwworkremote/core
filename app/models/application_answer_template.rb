# frozen_string_literal: true

# == Schema Information
#
# Table name: application_answer_templates
#
#  id                :bigint           not null, primary key
#  answer            :text             not null
#  enabled           :boolean          default(TRUE), not null
#  normalized_prompt :string           not null
#  prompt            :string           not null
#  question_kind     :string           not null
#  source            :string           default("manual"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  persona_id        :string
#  user_id           :bigint           not null
#
# Indexes
#
#  idx_answer_templates_lookup                    (user_id,persona_id,normalized_prompt)
#  index_application_answer_templates_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ApplicationAnswerTemplate < ApplicationRecord
  belongs_to :user

  validates :question_kind, :normalized_prompt, :prompt, :answer, :source, presence: true
  validates :source, inclusion: { in: %w[manual learned ai] }
end
