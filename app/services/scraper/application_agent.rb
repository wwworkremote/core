# frozen_string_literal: true

require 'playwright'

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
    return { success: false, error: 'No target URL' } if @job_posting.target_url.blank?

    Playwright.create(playwright_cli_executable_path: Rails.root.join('node_modules/.bin/playwright').to_s) do |playwright|
      playwright.chromium.launch(headless: false) do |browser| # Headful so you can see it work!
        page = browser.new_page
        page.goto(@job_posting.target_url)

        # 1. Identify 'Apply' Button
        apply_button = page.query_selector('text="Apply", text="Apply Now", .apply-button')
        if apply_button
          apply_button.click
          page.wait_for_load_state(state: 'networkidle')

          # 2. Attempt Auto-Fill (Foundation)
          # This is where we would map @profile data to form selectors
          auto_fill_form(page)

          { success: true, message: 'Navigated to application and attempted auto-fill.' }
        else
          { success: false, error: 'Could not find apply button.' }
        end
      end
    end
  end

  private

  def auto_fill_form(page)
    # Common selector mappings
    field_map = {
      'input[name*="first_name"]' => @user.name.split.first,
      'input[name*="last_name"]' => @user.name.split.last,
      'input[name*="email"]' => @user.email,
      'input[name*="phone"]' => @profile.contact_info&.[]('phone'),
      'textarea[name*="summary"]' => @profile.resume_text&.truncate(500)
    }

    field_map.each do |selector, value|
      page.fill(selector, value) if page.query_selector(selector) && value.present?
    end
  end
end
