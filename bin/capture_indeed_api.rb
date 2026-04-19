# frozen_string_literal: true

require 'playwright'

url = "https://www.indeed.com/jobs?q=Staff+Engineer&l=Remote&sc=0kf%3Aattr%28DSQF7%29%3B"

puts "Initiating Capture Session for Indeed: #{url}"

Playwright.create(playwright_cli_executable_path: Rails.root.join('node_modules', '.bin', 'playwright').to_s) do |playwright|
  playwright.chromium.launch(headless: true) do |browser|
    # Indeed is sensitive, use a real user agent
    user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    page = browser.new_page(userAgent: user_agent)
    
    # Intercept responses
    callback = ->(response) {
      if response.request.resource_type == 'fetch' || response.request.resource_type == 'xhr'
        begin
          if response.headers['content-type']&.include?('application/json')
            puts "\n--- JSON ENDPOINT DISCOVERED ---"
            puts "URL: #{response.url}"
            puts "Status: #{response.status}"
            body = response.text
            if body.include?('jobTitle') || body.include?('results') || body.include?('jobKeys')
              puts "Body snippet: #{body.slice(0, 500)}..."
            end
          end
        rescue StandardError
        end
      end
    }

    page.on('response', callback)

    puts "Navigating to Indeed..."
    page.goto(url, waitUntil: 'networkidle')
    puts "Page loaded. Waiting for background requests..."
    sleep 15
  end
end
