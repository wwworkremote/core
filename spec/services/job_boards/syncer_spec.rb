# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JobBoards::Syncer, type: :service do
  let(:service) { described_class.new }
  let(:source) { JobBoards::Source.find_or_create_by!(slug: 'remotive', name: 'Remotive') }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }
  let(:job_data) do
    {
      id: '123',
      title: 'Ruby Developer',
      description: 'Cool job',
      url: 'https://example.com/job',
      publication_date: '2024-01-01T12:00:00Z',
      company_name: 'Acme Corp',
      candidate_required_location: 'Worldwide'
    }
  end
  let(:document) do
    JobBoards::Document.create!(
      signature: 'remotive-123',
      source_id: source.id,
      job_boards_query_id: query.id,
      document: job_data.to_json
    )
  end

  describe '#call' do
    it 'creates a JobPosting from a JobBoards::Document' do
      document # Ensure document exists
      expect {
        service.call
      }.to change(JobPosting, :count).by(1)

      posting = JobPosting.last
      expect(posting.title).to eq('Ruby Developer')
      expect(posting.company_name).to eq('Acme Corp')
      expect(posting.signature).to eq('remotive-123')
    end

    it 'is idempotent' do
      document # Ensure document exists
      service.call
      expect {
        service.call
      }.not_to change(JobPosting, :count)
    end
  end
end
