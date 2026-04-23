# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Remotive::Fetcher, type: :service do
  let(:service) { described_class.new }
  let(:source) { JobBoards::Source.find_or_create_by!(slug: 'remotive', name: 'Remotive') }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }

  describe '#call', vcr: { cassette_name: 'remotive_fetch', allow_playback_repeats: true } do
    before do
      # Ensure source and query exist
      source
      query
    end

    it 'fetches remote jobs and stores them as documents' do
      expect {
        service.call(force: true)
      }.to change(JobBoards::Document, :count)

      doc = JobBoards::Document.last
      data = JSON.parse(doc.document)

      expect(doc.source_id).to eq(source.id)
      expect(data).to have_key('id')
      expect(data).to have_key('company_name')
      expect(data).to have_key('title')
    end

    it 'is idempotent and does not create duplicate documents' do
      service.call # First run
      initial_count = JobBoards::Document.count

      service.call # Second run
      expect(JobBoards::Document.count).to eq(initial_count)
    end
  end
end
