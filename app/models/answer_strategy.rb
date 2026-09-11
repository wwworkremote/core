# frozen_string_literal: true

# A provenance-bearing, versioned, persona-aware approach to answering a
# Question Archetype (ADR 008). Advisory only: nothing here is ever auto-filled
# or auto-submitted. "Most common" and "best answer" stay separate questions --
# frequency lives on the archetype, judgement lives in `confidence` + review.
# == Schema Information
#
# Table name: answer_strategies
#
#  id                    :bigint           not null, primary key
#  answer_text           :text             not null
#  confidence            :integer
#  enabled               :boolean          default(TRUE), not null
#  provenance            :jsonb            not null
#  sophistication        :string           not null
#  source                :string           not null
#  version               :integer          default(1), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  persona_id            :string
#  question_archetype_id :bigint           not null
#
# Indexes
#
#  idx_on_question_archetype_id_persona_id_source_b87f092534  (question_archetype_id,persona_id,source)
#  index_answer_strategies_on_question_archetype_id           (question_archetype_id)
#
# Foreign Keys
#
#  fk_rails_...  (question_archetype_id => question_archetypes.id)
#
class AnswerStrategy < ApplicationRecord
  SOURCES = %w[deterministic authored learned submitted ai].freeze
  # Answer Sophistication (ADR 008): how much reasoning the answer needs.
  SOPHISTICATIONS = %w[deterministic authored synthesized].freeze

  belongs_to :question_archetype

  validates :answer_text, :source, :sophistication, presence: true
  validates :source, inclusion: { in: SOURCES }
  validates :sophistication, inclusion: { in: SOPHISTICATIONS }
  validates :version, numericality: { only_integer: true, greater_than: 0 }
  validates :confidence, numericality: { in: 0..100 }, allow_nil: true

  scope :active, -> { where(enabled: true) }

  # The row that presents for a given persona: newest version wins, and a
  # persona-specific strategy outranks a generic one.
  scope :for_persona, lambda { |persona_id|
    where(persona_id: [persona_id, nil]).order(Arel.sql("persona_id IS NULL"), version: :desc)
  }
end
