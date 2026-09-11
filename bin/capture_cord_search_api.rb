# frozen_string_literal: true

require 'playwright'

url = "https://cord.com/search/jobs/software-developer"

puts "Initiating Capture Session for SEARCH: #{url}"

Playwright.create(playwright_cli_executable_path: Rails.root.join('node_modules', '.bin', 'playwright').to_s) do |playwright|
  playwright.chromium.launch(headless: true) do |browser|
    page = browser.new_page

    # Intercept responses
    callback = ->(response) {
      if response.request.resource_type == 'fetch' || response.request.resource_type == 'xhr'
        begin
          if response.headers['content-type']&.include?('application/json')
            puts "\n--- JSON ENDPOINT DISCOVERED ---"
            puts "URL: #{response.url}"
            puts "Status: #{response.status}"
            puts "Body snippet: #{response.text.slice(0, 500)}..." rescue "Body not readable"
          end
        rescue StandardError => e
        end
      end
    }

    page.on('response', callback)

    puts "Navigating to search page..."
    page.goto(url, waitUntil: 'networkidle')
    puts "Page loaded. Waiting for background requests..."
    sleep 5
  end
end
