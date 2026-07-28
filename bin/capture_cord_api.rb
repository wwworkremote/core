# frozen_string_literal: true

require 'playwright'

url = "https://cord.com/search/jobs/software-developer/u/youlend/jobs/367739-data-engineer"

puts "Initiating Capture Session for: #{url}"

Playwright.create(playwright_cli_executable_path: Rails.root.join('node_modules', '.bin', 'playwright').to_s) do |playwright|
  playwright.chromium.launch(headless: true) do |browser|
    page = browser.new_page

    # Intercept responses using proc
    callback = ->(response) {
      if response.request.resource_type == 'fetch' || response.request.resource_type == 'xhr'
        begin
          if response.headers['content-type']&.include?('application/json')
            puts "\n--- JSON ENDPOINT DISCOVERED ---"
            puts "URL: #{response.url}"
            puts "Status: #{response.status}"
            # body() returns a promise or the actual body depending on implementation
            # in ruby-client it is synchronous if called inside create block?
            # Actually response.body might throw if not available
            puts "Body snippet: #{response.text.slice(0, 500)}..." rescue "Body not readable"
          end
        rescue StandardError => e
          # puts "Error reading response: #{e.message}"
        end
      end
    }

    page.on('response', callback)

    puts "Navigating to page..."
    page.goto(url, waitUntil: 'networkidle')
    puts "Page loaded. Waiting for background requests..."
    sleep 10 # Increase wait for all requests to finish
  end
end
