# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Job Postings", type: :request do
  let!(:job) { JobPosting.create!(signature: 'test-1', title: 'Ruby Developer', company: 'Acme', published_at: Time.now) }

  describe "GET /job_postings" do
    it "returns a success response" do
      get job_postings_path, headers: { 'Host' => 'localhost' }
      expect(response).to be_successful
      expect(response.body).to include('Ruby Developer')
    end

    it "filters results by search query" do
      JobPosting.create!(signature: 'test-2', title: 'Python Dev', company: 'Other', published_at: Time.now)
      get job_postings_path, params: { q: 'Ruby' }, headers: { 'Host' => 'localhost' }
      expect(response.body).to include('Ruby Developer')
      expect(response.body).not_to include('Python Dev')
    end
  end

  describe "GET /job_postings/:id" do
    it "returns a success response" do
      get job_posting_path(job), headers: { 'Host' => 'localhost' }
      expect(response).to be_successful
      expect(response.body).to include('Ruby Developer')
      expect(response.body).to include('Acme')
    end
  end
end
