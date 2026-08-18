# frozen_string_literal: true

class JobPosting < ApplicationRecord
  include PgSearch::Model
  include JobPosting::LegacyCompanyAccess
  include JobPosting::StatusWorkflow
  include JobPosting::Geocoding
  include JobPosting::LocationFiltering

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
  has_many :application_questions, dependent: :destroy
  has_many :leads, dependent: :nullify

  def reformatting?
    data["reformatting"] == true
  end

  scope :recent, -> { order(Arel.sql("published_at DESC NULLS LAST")) }
  scope :contract_only, -> { where("data->>'employment_type' ILIKE ANY (ARRAY[?, ?])", "%contract%", "%temp%") }

  def self.by_role_family(family)
    aliases = RoleFamily.aliases_for(family)
    return none if aliases.empty?

    where(aliases.map { "title ILIKE ?" }.join(" OR "), *aliases.map { |a| "%#{a}%" })
  end

  # Postings this user hasn't run a ProfileMatcher check on yet have no
  # user_job_postings row at all -- LEFT JOIN (not INNER) keeps them in the
  # list, just sorted last (NULLS LAST) rather than dropped. The user_id
  # check has to live in the JOIN's ON clause, not a WHERE filter applied
  # after -- filtering in WHERE would drop a posting entirely whenever a
  # DIFFERENT user has a row for it (LEFT JOIN finds that other row, WHERE
  # then rejects it since it matches neither user.id nor NULL), instead of
  # correctly showing it unscored. Selects the joined score/tags as virtual
  # attributes so the index can display them without an N+1 per card.
  def self.by_match_score(user)
    joins(match_score_join_sql(user))
      .select("job_postings.*, user_job_postings.match_score AS current_match_score, " \
              "user_job_postings.match_tags AS current_match_tags")
      .order(Arel.sql("user_job_postings.match_score DESC NULLS LAST"))
  end

  def self.match_score_join_sql(user)
    condition = "LEFT JOIN user_job_postings ON user_job_postings.job_posting_id = job_postings.id " \
                "AND user_job_postings.user_id = ?"
    sanitize_sql_array([condition, user.id])
  end

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
  # tsearch reads the indexed tsv_search column (see migration). Trigram is
  # scoped to :title only -- fuzzy matching against multi-KB body text is
  # expensive per row regardless of indexing, and body content is already
  # covered by tsearch (stemmed) and hybrid_search's vector half. No
  # :threshold on trigram -- pg_search only emits the indexable `%` operator
  # when threshold is absent; setting one switches to `similarity() >= x`,
  # which forces a sequential scan.
  pg_search_scope :search,
                  against: { title: "A", body: "B" },
                  using: {
                    tsearch: { prefix: true, dictionary: "english", tsvector_column: "tsv_search" },
                    trigram: { only: [:title] }
                  }

  def self.semantic_search(query_text, limit: 10)
    VectorIntelligence.search(query_text, target_class: self, limit: limit)
  end

  # Fuses keyword (pg_search) and vector (pgvector cosine) result orderings
  # via Reciprocal Rank Fusion -- score[id] += 1/(rrf_k + rank) per list, no
  # score normalization needed since only rank position is used.
  def self.hybrid_search(query_text, limit: 10)
    return none if query_text.blank?

    ranked_ids = fused_candidate_ids(query_text, limit)
    return none if ranked_ids.empty?

    where(id: ranked_ids).in_order_of(:id, ranked_ids)
  end

  def self.fused_candidate_ids(query_text, limit)
    pool = limit * 3
    keyword_ids = search(query_text).limit(pool).pluck(:id)
    vector_ids = semantic_search(query_text, limit: pool).pluck(:id)
    fuse_rankings(keyword_ids, vector_ids).first(limit)
  end
  private_class_method :fused_candidate_ids

  def self.fuse_rankings(*ranked_id_lists, rrf_k: 60)
    rank_scores(ranked_id_lists, rrf_k).sort_by { |_id, score| -score }.map(&:first)
  end
  private_class_method :fuse_rankings

  def self.rank_scores(ranked_id_lists, rrf_k)
    scores = Hash.new(0.0)
    ranked_id_lists.each do |ids|
      ids.each_with_index { |id, idx| scores[id] += 1.0 / (rrf_k + idx + 1) }
    end
    scores
  end
  private_class_method :rank_scores

  def self.ransackable_attributes(_auth_object = nil)
    %w[id title company location published_at target_url source_id created_at updated_at latitude longitude]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[source domains target_domains]
  end

  # Real-time dashboard telemetry
  after_create_commit do
    broadcast_replace_to "system_telemetry", target: "synthesis_stats", partial: "home/telemetry_synthesis"
    broadcast_prepend_to "admin_live_feed", target: "live_ingestion", partial: "admin/dashboard/live_feed/job_posting",
                                            locals: { job_posting: self }
  end
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
#  embedding          :vector(768)
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
#  tsv_search         :tsvector
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
#  index_job_postings_on_embedding_hnsw                 (((embedding)::halfvec(768)) halfvec_cosine_ops) USING hnsw
#  index_job_postings_on_external_id                    (external_id)
#  index_job_postings_on_location                       (location)
#  index_job_postings_on_published_at                   (published_at)
#  index_job_postings_on_signature                      (signature) UNIQUE
#  index_job_postings_on_source_id_and_published_at     (source_id,published_at DESC)
#  index_job_postings_on_title                          (title) USING gin
#  index_job_postings_on_tsv_search                     (tsv_search) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (source_id => sources.id)
#
