# frozen_string_literal: true

require "playwright"

# Mints the short-lived session token ADP's career-site API requires --
# minted client-side only, so the one reliable source is a headless page
# load's own outgoing request headers. Split out of Adp::Fetcher to keep
# that class focused on the fetch/map flow shared with Greenhouse/Lever.
class Adp::TokenMinter
  CAREER_SITE_URL = "https://myjobs.adp.com"

  def self.call(board)
    new.call(board)
  end

  def call(board)
    mint(board)
  rescue StandardError => e
    # Playwright::DriverCrashedError (e.g. missing/broken Chromium) is a bare
    # StandardError, not a Playwright::Error -- caught here too so a driver
    # problem logs and returns nil instead of failing the enclosing job, same
    # as every other Playwright call site in this codebase.
    Rails.logger.error "[Adp::TokenMinter] Error minting token for #{board}: #{e.message}"
    nil
  end

  private

  def mint(board)
    token = nil
    Playwright.create(playwright_cli_executable_path: playwright_executable_path) do |pw|
      pw.chromium.launch(headless: true) { |browser| token = capture_token(browser, board) }
    end
    token
  end

  def playwright_executable_path
    Rails.root.join("node_modules/.bin/playwright").to_s
  end

  def capture_token(browser, board)
    page = browser.new_page
    box = listen_for_token(page)
    page.goto("#{CAREER_SITE_URL}/#{board}", waitUntil: "domcontentloaded")
    wait_for_token(page)
    box.first
  end

  def listen_for_token(page)
    box = []
    page.on("request", ->(req) { box << req.headers["myjobstoken"] if req.headers["myjobstoken"] })
    box
  end

  def wait_for_token(page)
    page.wait_for_load_state(state: "networkidle", timeout: 15_000)
  rescue Playwright::TimeoutError
    nil
  ensure
    sleep 3
  end
end
