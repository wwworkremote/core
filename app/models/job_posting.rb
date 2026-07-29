# frozen_string_literal: true

class JobPosting < ApplicationRecord
  include PgSearch::Model
  include JobPosting::LegacyCompanyAccess
  include JobPosting::StatusWorkflow

  validates :signature, presence: true, uniqueness: true

  has_neighbors :embedding # For vector similarity searches

  has_paper_trail
  belongs_to :source, optional: true
  belongs_to :company, optional: true

  has_many :target_domains, -> { readonly }, dependent: :restrict_with_error, inverse_of: :job_posting
  has_many :domains, -> { readonly }, through: :target_domains

  has_many :user_job_postings, dependent: :destroy
  has_many :users, through: :user_job_postings

  has_many :pipeline_steps, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :interview_sessions, dependent: :destroy
  has_many :interview_tasks, dependent: :destroy

  private

  def add_pipeline_note(note, link: nil)
    pipeline_steps.create!(status: "noted", note: note, link: link)
  end

  geocoded_by :location
  # after_validation :geocode, if: ->(obj) { obj.location.present? && obj.location_changed? }
  after_commit :enqueue_geocoding, on: %i[create update], if: lambda {
    location.present? && (saved_change_to_location? || latitude.nil?)
  }

  scope :recent, -> { order(published_at: :desc) }

  public

  def freshness
    return :unknown if published_at.nil?
    return :stale if stale?
    return :fresh if published_at > 24.hours.ago

    :normal
  end

  def stale?
    return false if published_at.nil?

    published_at < 72.hours.ago
  end
  pg_search_scope :search,
                  against: { title: "A", body: "B" },
                  using: {
                    tsearch: { prefix: true, dictionary: "english" },
                    trigram: { threshold: 0.1 }
                  }

  def self.semantic_search(query_text, limit: 10)
    VectorIntelligence.search(query_text, target_class: self, limit: limit)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id title company location published_at target_url source_id created_at updated_at latitude longitude]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[source domains target_domains]
  end

  def enqueue_geocoding
    JobBoards::GeocodingJob.perform_later(id)
  end

  def self.geocode_all
    where(latitude: nil, longitude: nil).where.not(location: nil).find_each do |posting|
      JobBoards::GeocodingJob.perform_later(posting.id)
    end
  end

  # Real-time dashboard telemetry
  after_create_commit do
    broadcast_replace_to "system_telemetry", target: "synthesis_stats", partial: "home/telemetry_synthesis"
    broadcast_prepend_to "admin_live_feed", target: "live_ingestion", partial: "admin/dashboard/live_feed/job_posting",
                                            locals: { job_posting: self }
  end

  # has_many :job_postings, -> { readonly }, dependent: :restrict_with_error, inverse_of: :source

  # rails_admin do
  #   label 'Job Posting'
  #   label_plural 'Job Postings'

  #   list do
  #     field :title do
  #       column_width 600
  #     end

  #     field :published_at, :datetime do
  #       label 'Published At'
  #       date_format :long
  #     end

  #     sort_by :published_at
  #   end
  # end
end

# == Schema Information
#
# Table name: job_postings
#
#  id                 :bigint           not null, primary key
#  body               :string
#  company_name       :string
#  country_code       :string
#  crawl_status       :string
#  data               :jsonb            not null
#  embedding          :vector(3584)
#  enriched_at        :datetime
#  latitude           :float
#  location           :string
#  longitude          :float
#  published_at       :datetime
#  seen_count         :integer          default(1), not null
#  signature          :string           not null
#  status             :string
#  tags               :string           is an Array
#  target_url         :string
#  title              :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  company_id         :bigint
#  external_author_id :string
#  external_id        :string
#  source_id          :bigint
#
# Indexes
#
#  index_job_postings_on_body                           (body) USING gin
#  index_job_postings_on_company_and_published_at       (company,published_at DESC)
#  index_job_postings_on_company_id                     (company_id)
#  index_job_postings_on_company_name                   (company_name)
#  index_job_postings_on_company_name_and_published_at  (company_name,published_at DESC)
#  index_job_postings_on_country_code                   (country_code)
#  index_job_postings_on_data                           (data) USING gin
#  index_job_postings_on_external_id                    (external_id)
#  index_job_postings_on_location                       (location)
#  index_job_postings_on_published_at                   (published_at)
#  index_job_postings_on_signature                      (signature) UNIQUE
#  index_job_postings_on_source_id_and_published_at     (source_id,published_at DESC)
#  index_job_postings_on_title                          (title) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (source_id => sources.id)
#
