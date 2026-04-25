# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Job Postings' do
  let(:origin) { Origin.find_or_create_by!(name: 'Test Origin') }
  let(:source) { Source.find_or_create_by!(signature: 'test-source', origin: origin) }
  let!(:job) {
    JobPosting.create!(signature: 'test-1', title: 'Ruby Developer', company: 'Acme', published_at: Time.zone.now,
                       source: source)
  }

  describe 'GET /job_postings' do
    it 'returns a success response' do
      host! '127.0.0.1'
      get job_postings_path
      expect(response).to be_successful
      expect(response.body).to include('Ruby Developer')
    end

    it 'filters results by search query' do
      host! '127.0.0.1'
      JobPosting.create!(signature: 'test-2', title: 'Python Dev', company: 'Other', published_at: Time.zone.now)
      get job_postings_path, params: { q: 'Ruby' }
      expect(response.body).to include('Ruby Developer')
      expect(response.body).not_to include('Python Dev')
    end
  end

  describe 'GET /job_postings/:id' do
    it 'returns a success response' do
      host! '127.0.0.1'
      get job_posting_path(job)
      expect(response).to be_successful
      expect(response.body).to include('Ruby Developer')
      expect(response.body).to include('Acme')
    end
  end
end
