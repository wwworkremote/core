# frozen_string_literal: true

# Immutable log of every "teach the extractor" event, kept even after
# ExtractionRule#selector is overwritten by a later teach for the same
# provider/field -- lets you see how a board's markup (and the selector
# chosen for it) drifted over time, e.g. via Admin::ExtractionRulesController#show.
# == Schema Information
#
# Table name: extraction_rule_observations
#
#  id                 :bigint           not null, primary key
#  candidate_selector :string
#  element_html       :text
#  field_name         :string           not null
#  learned_selector   :string           not null
#  parent_html        :text
#  provider           :string           not null
#  source_url         :string
#  created_at         :datetime         not null
#
# Indexes
#
#  index_extraction_rule_observations_on_provider_and_field_name  (provider,field_name)
#
class ExtractionRuleObservation < ApplicationRecord
  validates :provider, :field_name, :learned_selector, presence: true
end
