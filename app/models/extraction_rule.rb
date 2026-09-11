# frozen_string_literal: true

# A learned CSS selector for pulling one field out of one job board's DOM,
# taught via the extension's element picker (see Api::ExtractionRulesController
# and JobBoards::SelectorLearnerAgent). Content.js applies these as a
# field-level override on top of its existing JSON-LD/CSS/meta extraction
# chain -- scoped per provider, since LinkedIn's title selector has nothing
# to do with Indeed's.
# == Schema Information
#
# Table name: extraction_rules
#
#  id          :bigint           not null, primary key
#  field_name  :string           not null
#  provider    :string           not null
#  sample_html :text
#  selector    :string           not null
#  source_url  :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_extraction_rules_on_provider_and_field_name  (provider,field_name) UNIQUE
#
class ExtractionRule < ApplicationRecord
  validates :provider, :field_name, :selector, presence: true
  validates :field_name, uniqueness: { scope: :provider }
end
