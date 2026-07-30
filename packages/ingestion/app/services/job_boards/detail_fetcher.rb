# frozen_string_literal: true

require "ferrum"
require "reverse_markdown"

class JobBoards::DetailFetcher
  def call(limit: 20)
    jobs = target_jobs(limit)
    return if jobs.empty?

    process_jobs(jobs)
  end

  private

  # Find job postings that need detail enrichment
  # e.g. those where body is short or missing, or not recently updated
  def target_jobs(limit)
    JobPosting.where("length(body) < 500 OR body IS NULL")
              .order(updated_at: :desc)
              .limit(limit)
  end

  def build_browser
    Ferrum::Browser.new(
      timeout: 45,
      window_size: [1920, 1080],
      browser_options: { "disable-blink-features": "AutomationControlled" }
    )
  end

  def process_jobs(jobs)
    browser = build_browser
    jobs.each { |job| enrich_job(browser, job) }
  ensure
    browser&.quit
  end

  def enrich_job(browser, job)
    load_page(browser, job)
    description = extract_description(browser)
    apply_enrichment(job, description) if better_description?(description, job)

    # Anti-rate-limiting for personal use
    sleep rand(2..5)
  end

  def better_description?(description, job)
    description.present? && description.length > (job.body&.length || 0)
  end

  def load_page(browser, job)
    puts "Enriching job: #{job.title} from #{job.target_url}"
    browser.goto(job.target_url)

    # Wait for content to render (Personal local use allows for generous waits)
    sleep 5
    browser.network.wait_for_idle
  end

  # Smart content extraction: try common job description containers, or
  # fall back to the full page body text.
  # rubocop:disable Metrics/MethodLength
  def extract_description(browser)
    browser.evaluate("() => {
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
  end
  # rubocop:enable Metrics/MethodLength

  def apply_enrichment(job, description)
    job.update!(body: normalize_body(description))
    # Re-categorize after enrichment
    Categorizer.new(job).call
    puts "SUCCESS: Enriched description for #{job.title}"
  end

  def normalize_body(html)
    return nil if html.blank?

    # Convert HTML to Markdown
    ReverseMarkdown.convert(html, unknown_tags: :bypass, github_flavored: true).strip
  end
end
