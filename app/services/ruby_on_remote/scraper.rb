# frozen_string_literal: true

require 'ferrum'

module RubyOnRemote
  class Scraper
    include ApiGuard

    BASE_URL = 'https://rubyonremote.com'

    def call(force: false)
      with_api_guard('rubyonremote', cooldown: 4.hours, force:) do |source|
        query = JobBoards::Query.find_or_create_by!(source_id: source.id)

        browser = Ferrum::Browser.new(timeout: 45, window_size: [1920, 1080])
        begin
          browser.goto(BASE_URL)

          # Wait for Cloudflare challenge and React mount
          # Cloudflare usually takes 5-10s
          sleep 15
          browser.network.wait_for_idle

          puts "RubyOnRemote: Capturing page state..."
          browser.screenshot(path: 'tmp/rubyonremote.png')
          File.write('tmp/rubyonremote.html', browser.body)

          # Extract job listings
          # Selector based on typical RubyOnRemote structure
          jobs_data = browser.evaluate("() => {
            return Array.from(document.querySelectorAll('.job-card, .job-listing')).map(card => {
              const link = card.querySelector('a[href*=\"/jobs/\"]');
              return {
                id: link?.href.split('/').pop() || Math.random().toString(36).substr(2, 9),
                title: card.querySelector('h2, .job-title')?.innerText.trim(),
                company: card.querySelector('.company-name, .company')?.innerText.trim(),
                url: link?.href,
                location: card.querySelector('.location')?.innerText.trim(),
                tags: Array.from(card.querySelectorAll('.tag, .category')).map(t => t.innerText.trim())
              }
            })
          }")

          (jobs_data || []).each do |job_data|
            next if job_data['title'].blank?

            signature = "rubyonremote-#{job_data['id']}"

            JobBoards::Document.find_or_create_by!(signature: signature) do |doc|
              doc.source_id = source.id
              doc.job_boards_query_id = query.id
              doc.document = job_data.to_json
            end
          end

          Rails.logger.info "RubyOnRemote Scraper: Found #{jobs_data&.count || 0} jobs."
          true
        ensure
          browser.quit
        end
      end
    rescue StandardError => e
      Rails.logger.error "RubyOnRemote Scraper Error: #{e.message}"
      false
    end
  end
end
