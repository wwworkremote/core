# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arbeitnow::Fetcher, type: :service do
  let(:service) { described_class.new }
  let(:source) { JobBoards::Source.find_or_create_by!(slug: 'arbeitnow', name: 'Arbeitnow') }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }

  describe '#call', vcr: { cassette_name: 'arbeitnow_fetch', allow_playback_repeats: true } do
    before do
      source
      query
    end

    it 'fetches JSON jobs and stores them as documents' do
      expect {
        service.call
      }.to change(JobBoards::Document, :count)

      doc = JobBoards::Document.last
      data = JSON.parse(doc.document)
      
      expect(doc.source_id).to eq(source.id)
      expect(data).to have_key('slug')
      expect(data).to have_key('company_name')
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
