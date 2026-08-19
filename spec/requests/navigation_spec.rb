# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Navigation" do
  describe "GET / (primary layout)" do
    it "has no translation_missing errors -- regression for a long-standing i18n gap" do
      get root_path
      expect(response.body).not_to include("translation missing")
    end

    it "has a skip-to-content link targeting the main landmark" do
      get root_path
      expect(response.body).to include('href="#main-content"')
      expect(response.body).to include('id="main-content"')
    end

    it "wraps the primary nav in a labeled <nav> landmark" do
      get root_path
      expect(response.body).to include('<nav aria-label="Primary"')
    end

    it "marks the current page's nav link with aria-current" do
      get root_path
      expect(response.body).to match(%r{<a[^>]*aria-current="page"[^>]*href="/">Dashboard})
    end
  end

  describe "GET /companies" do
    it "marks Companies, not Dashboard, as the current nav link" do
      get companies_path
      expect(response.body).to match(%r{<a[^>]*aria-current="page"[^>]*href="/companies">Companies})
      expect(response.body).not_to match(%r{<a[^>]*aria-current="page"[^>]*href="/">Dashboard})
    end
  end

  describe "GET /admin/sources (admin nav)" do
    it "wraps the admin nav in a labeled <nav> landmark and marks the current section" do
      get admin_sources_path
      expect(response.body).to include('<nav aria-label="Admin"')
      expect(response.body).to match(%r{<a[^>]*aria-current="page"[^>]*href="/admin/sources">Sources})
    end
  end
end
