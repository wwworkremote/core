# frozen_string_literal: true

class JobPosting < ApplicationRecord
  include PgSearch::Model

  validates :signature, presence: true, uniqueness: true

  has_neighbors :embedding # For vector similarity searches

  has_paper_trail
  belongs_to :source, optional: true

  has_many :target_domains, -> { readonly }, dependent: :restrict_with_error, inverse_of: :job_posting
  has_many :domains, -> { readonly }, through: :target_domains

  geocoded_by :location
  after_validation :geocode, if: ->(obj) { obj.location.present? && obj.location_changed? }

  scope :recent, -> { order(published_at: :desc) }

  # Advanced full-text search
  pg_search_scope :search,
                  against: { title: 'A', body: 'B' },
                  using: {
                    tsearch: { prefix: true, dictionary: 'english' },
                    trigram: { threshold: 0.1 }
                  }

  def self.semantic_search(query_text, limit: 10)
    embedding = JobBoards::Embedder.embed_text(query_text)
    return none if embedding.blank?

    nearest_neighbors(:embedding, embedding, distance: 'cosine').limit(limit)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id title company location published_at target_url source_id created_at updated_at latitude longitude]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[source domains target_domains]
  end

  def self.geocode_all
    where(latitude: nil, longitude: nil).where.not(location: nil).find_each do |posting|
      posting.geocode
      posting.save
      sleep(1.0) # Be kind to the geocoding API (Nominatim limit is 1 req/sec)
    end
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
#  company            :string
#  data               :jsonb            not null
#  embedding          :vector(1536)
#  latitude           :float
#  location           :string
#  longitude          :float
#  published_at       :datetime
#  signature          :string           not null
#  tags               :string           is an Array
#  target_url         :string
#  title              :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  external_author_id :string
#  external_id        :string
#  source_id          :bigint
#
# Indexes
#
#  index_job_postings_on_body       (body) USING gin
#  index_job_postings_on_source_id  (source_id)
#  index_job_postings_on_title      (title) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (source_id => sources.id)
#
