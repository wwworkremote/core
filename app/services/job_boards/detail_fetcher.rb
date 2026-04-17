# frozen_string_literal: true

require 'ferrum'
require 'reverse_markdown'

module JobBoards
  class DetailFetcher
    def call(limit: 20)
      # Find job postings that need detail enrichment
      # e.g. those where body is short or missing, or not recently updated
      jobs = JobPosting.where('length(body) < 500 OR body IS NULL')
                       .order(updated_at: :desc)
                       .limit(limit)

      return if jobs.empty?

      browser = Ferrum::Browser.new(
        timeout: 45,
        window_size: [1920, 1080],
        browser_options: { 'disable-blink-features': 'AutomationControlled' }
      )

      begin
        jobs.each do |job|
          puts "Enriching job: #{job.title} from #{job.target_url}"
          browser.goto(job.target_url)

          # Wait for content to render (Personal local use allows for generous waits)
          sleep 5
          browser.network.wait_for_idle

          # Smart content extraction
          # Try common job description containers or fallback to body text
          description = browser.evaluate("() => {
            const selectors = [
              '[class*=\"description\"]',
              '[id*=\"description\"]',
              'article',
              '.job-details',
              '.opening'
            ];
            for (const s of selectors) {
              const el = document.querySelector(s);
              if (el && el.innerText.length > 500) return el.innerHTML;
            }
            return document.body.innerText;
          }")

          if description.present? && description.length > (job.body&.length || 0)
            job.update!(body: normalize_body(description))
            # Re-categorize after enrichment
            Categorizer.new(job).call
            puts "SUCCESS: Enriched description for #{job.title}"
          end

          # Anti-rate-limiting for personal use
          sleep rand(2..5)
        end
      ensure
        browser.quit
      end
    end

    private

    def normalize_body(html)
      return nil if html.blank?

      # Convert HTML to Markdown
      ReverseMarkdown.convert(html, unknown_tags: :bypass, github_flavored: true).strip
    end
  end
end
