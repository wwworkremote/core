# frozen_string_literal: true

# == Schema Information
#
# Table name: companies
#
#  id                 :bigint           not null, primary key
#  disposition        :string
#  glassdoor_data     :jsonb
#  ingestion_enabled  :boolean          default(TRUE), not null
#  name               :string
#  sentiment_score    :float
#  slug               :string
#  status             :string
#  toxic_culture_flag :boolean
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_companies_on_name       (name) UNIQUE
#  index_companies_on_name_trgm  (name) USING gin
#  index_companies_on_slug       (slug) UNIQUE
#
class Company < ApplicationRecord
  include AASM

  has_many :company_pipeline_steps, dependent: :destroy
  has_many :job_postings, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  # Classic FAANG + mega-cap tech -- companies whose scale/stage no longer
  # fits where the user is in their career. Edit this list directly; no
  # migration or redeploy needed beyond a code change.
  BIG_TECH_NAMES = %w[
    meta facebook apple amazon aws netflix google alphabet
    microsoft nvidia tesla oracle salesforce
  ].freeze

  # Word-boundary matched to avoid overmatching (e.g. "Metadata Corp").
  # Ruby (Onigmo) and Postgres (POSIX ARE) spell "word boundary"
  # differently -- \b vs \y -- so each engine gets its own pattern
  # generated from the same word list rather than sharing one string.
  BIG_TECH_NAME_REGEXP = Regexp.new(BIG_TECH_NAMES.map { |n| "\\b#{n}\\b" }.join("|"), Regexp::IGNORECASE)
  BIG_TECH_NAME_PATTERN = BIG_TECH_NAMES.map { |n| "\\y#{n}\\y" }.join("|")

  scope :big_tech, -> { where("name ~* ?", BIG_TECH_NAME_PATTERN) }

  aasm column: :status do
    state :none, initial: true
    state :favorited, :archived

    event :favorite do
      transitions from: %i[none archived], to: :favorited
    end

    event :archive do
      transitions from: [:favorited], to: :archived
    end
  end

  def add_pipeline_note(note, link: nil)
    company_pipeline_steps.create!(status: "noted", note: note, link: link)
  end

  def big_tech?
    name.to_s.match?(BIG_TECH_NAME_REGEXP)
  end

  # Disables future ingestion and purges any existing non-purged postings --
  # the same cascade the admin toggle_ingestion action performs, extracted
  # here so the big-tech blocklist backfill (rake task) can share it.
  # Skips expired postings: AASM's purge event doesn't allow transitioning
  # from :expired, and expired postings are already excluded from every
  # default listing, so there's nothing extra to hide by purging them.
  def disable_ingestion!
    update!(ingestion_enabled: false)
    job_postings.where.not(status: %w[purged expired]).find_each(&:purge!)
  end

  # Softer sibling of disable_ingestion! for a company the user just isn't
  # interested in (vs. a hard blocklist purge): stops future postings the
  # same way (CompanyResolver already auto-ignores new postings when
  # ingestion_enabled is false), but *ignores* rather than purges existing
  # ones, matching the same "Not interested" semantics as a single job
  # posting -- only untouched postings are affected (without_pipeline_activity,
  # TASK-82 phase 3), so anything already favorited/applied/etc is left alone.
  def mark_not_interested!
    update!(ingestion_enabled: false)
    job_postings.where(status: "none").without_pipeline_activity(User.sole).find_each(&:ignore!)
  end

  def to_s
    name
  end
end
