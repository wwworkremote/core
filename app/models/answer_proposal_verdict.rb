# frozen_string_literal: true

# Value-free record of one answer proposal shown to Mike and what he did with
# it (TASK-127, shape from wayfinder doc-7 TASK-124). sha256 hashes + edit
# distance only -- the answer text already lives on the occurrence / the
# ApplicationQuestion, and never belongs in this analytics table.
#
# One row per proposal shown, declines included (proposal generated, panel or
# page closed without using it).
# == Schema Information
#
# Table name: answer_proposal_verdicts
#
#  id                     :bigint           not null, primary key
#  decided_at             :datetime         not null
#  edit_distance          :integer
#  final_text_sha256      :string
#  proposed_text_sha256   :string           not null
#  provider               :string
#  strategy_source        :string           not null
#  verdict                :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  persona_id             :string
#  question_archetype_id  :bigint           not null
#  question_occurrence_id :bigint
#
# Indexes
#
#  idx_on_question_archetype_id_strategy_source_verdic_589ef49dee  (question_archetype_id,strategy_source,verdict)
#  index_answer_proposal_verdicts_on_question_archetype_id         (question_archetype_id)
#  index_answer_proposal_verdicts_on_question_occurrence_id        (question_occurrence_id)
#
# Foreign Keys
#
#  fk_rails_...  (question_archetype_id => question_archetypes.id)
#  fk_rails_...  (question_occurrence_id => question_occurrences.id)
#
class AnswerProposalVerdict < ApplicationRecord
  VERDICTS = %w[accepted edited declined].freeze
  STRATEGY_SOURCES = %w[canned template ai].freeze

  belongs_to :question_archetype
  belongs_to :question_occurrence, optional: true

  validates :strategy_source, inclusion: { in: STRATEGY_SOURCES }
  validates :verdict, inclusion: { in: VERDICTS }
  validates :proposed_text_sha256, presence: true
  validates :decided_at, presence: true
  validate :value_free_columns

  before_validation { self.decided_at ||= Time.current }

  scope :with_enough_evidence, lambda { |floor|
    group(:question_archetype_id).having("count(*) >= ?", floor).count.keys
  }

  private

  # Belt-and-suspenders: reject anything that looks like raw answer text in
  # the hash columns (they must be 64-hex sha256 digests or nil).
  def value_free_columns
    %i[proposed_text_sha256 final_text_sha256].each do |column|
      value = self[column]
      errors.add(column, "must be a sha256 digest") if value.present? && !value.match?(/\A[0-9a-f]{64}\z/)
    end
  end
end
