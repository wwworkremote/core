# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Adzuna::Fetcher, type: :service do
  let(:service) { described_class.new }
  let(:source) { JobBoards::Source.find_or_create_by!(slug: 'adzuna', name: 'Adzuna') }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }

  describe '#call' do
    before do
      source
      query
      allow(ENV).to receive(:fetch).with('ADZUNA_APPLICATION_ID', nil).and_return('test_id')
      allow(ENV).to receive(:fetch).with('ADZUNA_APPLICATION_KEY', nil).and_return('test_key')

      stub_request(:get, /api.adzuna.com/)
        .to_return(status: 200, body: {
          results: [
            { id: '123', title: 'Remote Ruby Dev', company: { display_name: 'Test Co' } }
          ]
        }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'fetches JSON jobs and stores them as documents' do
      expect {
        service.call
      }.to change(JobBoards::Document, :count)

      doc = JobBoards::Document.last
      data = JSON.parse(doc.document)
      
      expect(doc.source_id).to eq(source.id)
      expect(data).to have_key('id')
      expect(data).to have_key('title')
    end

    it 'is idempotent' do
      service.call
      initial_count = JobBoards::Document.count

      service.call
      expect(JobBoards::Document.count).to eq(initial_count)
    end
  end
end
