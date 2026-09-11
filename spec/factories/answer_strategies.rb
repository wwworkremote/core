# frozen_string_literal: true

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
FactoryBot.define do
  factory :answer_strategy do
    question_archetype
    answer_text { "Because the mission resonates with my background." }
    source { "authored" }
    sophistication { "authored" }
  end
end
