# frozen_string_literal: true

require 'nokogiri'

class Yc::Scraper
  include ApiGuard

  BASE_URL = 'https://www.workatastartup.com/jobs'

  def call(force: false)
    with_api_guard('yc', cooldown: 4.hours, force:) do |source|
      query = JobBoards::Query.find_or_create_by!(source_id: source.id)

      client = JobBoards::Client.new('yc')
      response = client.get(BASE_URL)
      return false if response.nil? || response.status != 200

      doc = Nokogiri::HTML(response.body)
      data_attr = doc.at_css('div[data-page]')&.[]('data-page')
      return false unless data_attr

      json_data = JSON.parse(CGI.unescape_html(data_attr))
      jobs = json_data.dig('props', 'jobs') || []

      jobs.each do |job_data|
        signature = "yc-#{job_data['id']}"

        JobBoards::Document.find_or_create_by!(signature: signature) do |doc_record|
          doc_attr = {
            id: job_data['id'],
            title: job_data['title'],
            company: job_data['companyName'],
            description: job_data['companyOneLiner'], # Full desc requires sub-page fetch
            url: "https://www.workatastartup.com/jobs/#{job_data['id']}",
            location: job_data['location'],
            role_type: job_data['roleType']
          }
          doc_record.source_id = source.id
          doc_record.job_boards_query_id = query.id
          doc_record.document = doc_attr.to_json
        end
      end

      Rails.logger.info "YC Scraper: Extracted #{jobs.count} jobs from embedded JSON."
      true
    end
  end
end
