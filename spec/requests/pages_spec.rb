# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pages" do
  describe "GET /about" do
    it "renders the about page" do
      get about_path
      expect(response).to be_successful
    end
  end

  describe "GET /pages/:page for an unrecognized page" do
    it "renders the static 404 page" do
      get "/pages/not-a-real-page"
      expect(response).to have_http_status(:not_found)
    end
  end
end
