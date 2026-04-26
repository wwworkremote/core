# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Domains", type: :request do
  let!(:domain) { create(:domain, name: "example.com") }

  describe "GET /admin/domains" do
    it "returns a success response" do
      get admin_domains_path
      expect(response).to be_successful
      expect(response.body).to include("example.com")
    end
  end

  describe "GET /admin/domains/:id" do
    it "returns a success response" do
      get admin_domain_path(domain)
      expect(response).to be_successful
      expect(response.body).to include("example.com")
    end
  end

  describe "DELETE /admin/domains/:id" do
    it "destroys the domain and redirects" do
      expect {
        delete admin_domain_path(domain)
      }.to change(Domain, :count).by(-1)

      expect(response).to redirect_to(admin_domains_path)
    end
  end
end
