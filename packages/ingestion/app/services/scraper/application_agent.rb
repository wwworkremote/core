# frozen_string_literal: true

require "playwright"

class Scraper::ApplicationAgent
  def self.call(job_posting, user)
    new(job_posting, user).call
  end

  def initialize(job_posting, user)
    @job_posting = job_posting
    @user = user
    @profile = user.career_profile
  end

  def call
    return { success: false, error: "No target URL" } if @job_posting.target_url.blank?

    with_browser_page { |page| attempt_application(page) }
  end

  private

  def with_browser_page
    Playwright.create(playwright_cli_executable_path: playwright_cli_path) do |playwright|
      playwright.chromium.launch(headless: false) do |browser| # Headful so you can see it work!
        yield browser.new_page
      end
    end
  end

  def playwright_cli_path
    Rails.root.join("node_modules/.bin/playwright").to_s
  end

  def attempt_application(page)
    page.goto(@job_posting.target_url)
    apply_button = page.query_selector('text="Apply", text="Apply Now", .apply-button')
    return { success: false, error: "Could not find apply button." } unless apply_button

    click_and_fill(page, apply_button)
  end

  def click_and_fill(page, apply_button)
    apply_button.click
    page.wait_for_load_state(state: "networkidle")
    auto_fill_form(page)
    { success: true, message: "Navigated to application and attempted auto-fill." }
  end

  def auto_fill_form(page)
    field_map.each { |selector, value| fill_field(page, selector, value) }
  end

  def field_map
    name_fields.merge(contact_fields)
  end

  def name_fields
    {
      'input[name*="first_name"]' => @user.name.split.first,
      'input[name*="last_name"]' => @user.name.split.last,
      'input[name*="email"]' => @user.email
    }
  end

  def contact_fields
    {
      'input[name*="phone"]' => @profile.contact_info&.[]("phone"),
      'textarea[name*="summary"]' => resume_summary
    }
  end

  def resume_summary
    @profile.resume_text&.truncate(500)
  end

  def fill_field(page, selector, value)
    page.fill(selector, value) if page.query_selector(selector) && value.present?
  end
end
