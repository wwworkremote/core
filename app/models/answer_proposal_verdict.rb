# frozen_string_literal: true

# Value-free record of one answer proposal shown to Mike and what he did with
# it (TASK-127, shape from wayfinder doc-7 TASK-124). sha256 hashes + edit
# distance only -- the answer text already lives on the occurrence / the
# ApplicationQuestion, and never belongs in this analytics table.
#
# One row per proposal shown, declines included (proposal generated, panel or
# page closed without using it).
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
