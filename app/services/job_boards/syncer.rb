# frozen_string_literal: true

require 'reverse_markdown'

module JobBoards
  class Syncer
    def call
      JobBoards::Document.where(aasm_state: ['pending', nil]).find_each do |doc|
        sync_document(doc)
      end
    rescue ActiveRecord::ConnectionTimeoutError => e
      Rails.logger.error "[Syncer] Database connection pool exhausted: #{e.message}. Halting sync."
    end

    private

    def sync_document(doc)
      source = JobBoards::Source.find(doc.source_id)
      data = JSON.parse(doc.document)

      origin = Origin.find_or_create_by!(name: source.name)
      dashboard_source = ::Source.find_or_create_by!(signature: "#{source.slug}-default") { |s| s.origin = origin }

      JobPosting.find_or_initialize_by(signature: doc.signature) do |jp|
        jp.source_id = dashboard_source.id
        map_attributes(jp, data, source.slug)
        jp.save!

        JobBoards::Categorizer.new(jp).call
        JobBoards::Embedder.new(jp).call
      end
    end

    def map_attributes(jp, data, slug)
      case slug
      when 'hackernews'
        jp.title        = data['title']
        jp.body         = data['text']
        jp.target_url   = data['url']
        jp.published_at = Time.zone.at(data['time'])
      when 'arbeitnow'
        jp.title        = data['title']
        jp.body         = data['description']
        jp.target_url   = data['url']
        jp.published_at = Time.zone.at(data['created_at'])
        jp.company      = data['company_name']
        jp.location     = data['location']
        jp.tags         = data['tags']
      when 'adzuna'
        jp.title        = data['title']
        jp.body         = data['description']
        jp.target_url   = data['redirect_url']
        jp.published_at = Time.zone.parse(data['created'])
        jp.company      = data.dig('company', 'display_name')
        jp.location     = data.dig('location', 'display_name')
      when 'remotive'
        jp.title        = data['title']
        jp.body         = data['description']
        jp.target_url   = data['url']
        jp.published_at = Time.zone.parse(data['publication_date'])
        jp.company      = data['company_name']
        jp.location     = data['candidate_required_location']
      when 'wwr'
        jp.title        = data['title']
        jp.body         = data['content'] || data['summary']
        jp.target_url   = data['url']
        jp.published_at = Time.zone.parse(data['published'])
        jp.company      = parse_wwr_company(data['title'])
      when 'remoteok'
        jp.title        = data['position']
        jp.body         = data['description']
        jp.target_url   = data['url']
        jp.published_at = Time.zone.at(data['date'].to_i)
        jp.company      = data['company']
        jp.location     = data['location']
        jp.tags         = data['tags']
      when 'jobicy'
        jp.title        = data['jobTitle']
        jp.body         = data['jobDescription']
        jp.target_url   = data['url']
        jp.published_at = Time.zone.parse(data['pubDate']) rescue Time.zone.now
        jp.company      = data['companyName']
        jp.location     = data['jobGeo']
      when 'greenhouse'
        jp.title        = data['title']
        jp.body         = data['content']
        jp.target_url   = data['absolute_url']
        jp.published_at = Time.zone.parse(data['updated_at']) rescue Time.zone.now
        jp.company      = data['company_name']
        jp.location     = data.dig('location', 'name')
      when 'lever'
        jp.title        = data['text']
        jp.body         = data['description']
        jp.target_url   = data['hostedUrl']
        jp.published_at = Time.zone.at(data['createdAt'] / 1000) rescue Time.zone.now
        jp.company      = data['site_slug']&.capitalize
        jp.location     = data.dig('categories', 'location')
        jp.tags         = Array(data.dig('categories', 'team'))
      when 'yc'
        jp.title        = data['title']
        jp.body         = data['description']
        jp.target_url   = data['url']
        jp.published_at = Time.zone.now
        jp.company      = data['company']
        jp.location     = data['location']
        jp.tags         = Array(data['role_type'])
      when 'email_ingestion'
        jp.title        = data['title']
        jp.body         = data['description']
        jp.target_url   = data['canonical_url'] || data['url']
        jp.published_at = Time.zone.parse(data['email_received_at']) rescue Time.zone.now
        jp.company      = data['company']
        jp.location     = data['location']
      end

      # Preserve intersection data in the JobPosting payload
      jp.data = data.merge('found_by_terms' => data['found_by_terms'])
      jp.body = normalize_body(jp.body)
    end

    def normalize_body(html)
      return nil if html.blank?

      # Convert HTML to Markdown
      ReverseMarkdown.convert(html, unknown_tags: :bypass, github_flavored: true).strip
    end

    def parse_wwr_company(title)
      # WWR titles are often "Company Name: Job Title"
      title.split(':').first.strip
    end
  end
end
