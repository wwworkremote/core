# frozen_string_literal: true

module JobBoards
  class Syncer
    def call
      JobBoards::Document.find_each do |doc|
        sync_document(doc)
      end
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

        Categorizer.new(jp).call
      end
    end
    def map_attributes(jp, data, slug)
      case slug
      when 'hackernews'
        jp.title        = data['title']
        jp.body         = data['text']
        jp.target_url   = data['url']
        jp.published_at = Time.at(data['time'])
      when 'arbeitnow'
        jp.title        = data['title']
        jp.body         = data['description']
        jp.target_url   = data['url']
        jp.published_at = Time.at(data['created_at'])
        jp.company      = data['company_name']
        jp.location     = data['location']
        jp.tags         = data['tags']
      when 'adzuna'
      when 'remotive'
        jp.title        = data['title']
        jp.body         = data['description']
        jp.target_url   = data['url']
        jp.published_at = Time.parse(data['publication_date'])
        jp.company      = data['company_name']
        jp.location     = data['candidate_required_location']
      when 'wwr'
        jp.title        = data['title']
        jp.body         = data['content'] || data['summary']
        jp.target_url   = data['url']
        jp.published_at = Time.parse(data['published'])
        jp.company      = parse_wwr_company(data['title'])
      when 'arbeitnow'
        jp.title        = data['title']
        jp.body         = data['description']
        jp.target_url   = data['url']
        jp.published_at = Time.at(data['created_at'])
        jp.company      = data['company_name']
        jp.location     = data['location']
      when 'adzuna'
        jp.title        = data['title']
        jp.body         = data['description']
        jp.target_url   = data['redirect_url']
        jp.published_at = Time.parse(data['created'])
        jp.company      = data.dig('company', 'display_name')
        jp.location     = data.dig('location', 'display_name')
      when 'himalayas'
        jp.title        = data['title']
        jp.body         = data['description']
        jp.target_url   = data['application_link'] || data['link']
        jp.published_at = Time.parse(data['published_at'])
        jp.company      = data.dig('company', 'name')
        jp.location     = data['location']
      when 'remoteok'
        jp.title        = data['position']
        jp.body         = data['description']
        jp.target_url   = data['url']
        jp.published_at = Time.at(data['date'].to_i)
        jp.company      = data['company']
        jp.location     = data['location']
        jp.tags         = data['tags']
      when 'jobicy'
        jp.title        = data['jobTitle']
        jp.body         = data['jobDescription']
        jp.target_url   = data['url']
        jp.published_at = Time.parse(data['pubDate']) rescue Time.now
        jp.company      = data['companyName']
        jp.location     = data['jobGeo']
      when 'rubyonremote'
        jp.title        = data['title']
        jp.body         = data['description'] # Might be nil from index
        jp.target_url   = data['url']
        jp.published_at = Time.now
        jp.company      = data['company']
        jp.location     = data['location']
        jp.tags         = data['tags']
      when 'yc'
        jp.title        = data['title']
        jp.body         = data['description']
        jp.target_url   = data['url']
        jp.published_at = Time.now
        jp.company      = data['company']
        jp.location     = data['location']
        jp.tags         = Array(data['role_type'])
      end
      jp.data = data
    end

    def parse_wwr_company(title)
      # WWR titles are often "Company Name: Job Title"
      title.split(':').first.strip
    end
  end
end
