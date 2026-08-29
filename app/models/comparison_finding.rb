# frozen_string_literal: true

# One thing a ReferenceComparison run inferred: a single drift or coverage gap
# (ADR 009). Immutable. `locator` is the stable string identifying what
# diverged -- for drift it is the signature kind (`field:email`,
# `screening_question:v1:<sha>`), for a coverage gap the reference checkpoint
# kind. `dimension` uses the Scenarios::SignatureKind vocabulary.
#
# A finding may carry a `suggested_disposition` (a prior FindingDisposition for
# the same (dimension, locator) on the same provider + reference) -- a
# presentation default only. The finding is not dispositioned until a real
# FindingDisposition row is written against it.
# == Schema Information
#
# Table name: comparison_findings
#
#  id                       :bigint           not null, primary key
#  category                 :string           not null
#  detail                   :jsonb            not null
#  dimension                :string           not null
#  locator                  :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  reference_comparison_id  :bigint           not null
#  suggested_disposition_id :bigint
#
# Indexes
#
#  index_comparison_findings_on_dimension_and_locator    (dimension,locator)
#  index_comparison_findings_on_reference_comparison_id  (reference_comparison_id)
#
# Foreign Keys
#
#  fk_rails_...  (reference_comparison_id => reference_comparisons.id)
#
class ComparisonFinding < ApplicationRecord
  CATEGORIES = %w[drift coverage_gap].freeze
  DIMENSIONS = %w[ats_identity field screening_question step commitment_boundary unknown_namespace].freeze

  belongs_to :reference_comparison
  belongs_to :suggested_disposition, class_name: "FindingDisposition", optional: true
  has_many :finding_dispositions, dependent: :destroy

  validates :category, inclusion: { in: CATEGORIES }
  validates :dimension, inclusion: { in: DIMENSIONS }
  validates :locator, presence: true

  # Immutable after creation.
  def readonly? = persisted?

  # Latest applicable human judgment; history stays in #finding_dispositions.
  # Ruby-side max so an eager-loaded association is reused by the review page.
  def current_disposition
    finding_dispositions.max_by { |disposition| [disposition.created_at, disposition.id] }
  end

  def dispositioned?
    current_disposition.present?
  end
end
