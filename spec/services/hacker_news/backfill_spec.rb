# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HackerNews::Backfill, type: :service do
  let(:service) { described_class.new }
  let(:source) { JobBoards::Source.find_or_create_by!(slug: 'hackernews', name: 'Hacker News') }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }

  describe '#call', vcr: { cassette_name: 'hn_backfill', allow_playback_repeats: true } do
    before do
      source
      query
    end

    it 'fetches historic jobs from Algolia and stores them as documents' do
      expect {
        service.call(before_timestamp: 1_772_468_371)
      }.to change(JobBoards::Document, :count)

      doc = JobBoards::Document.last
      data = JSON.parse(doc.document)

      expect(doc.source_id).to eq(source.id)
      expect(data).to have_key('id')
      expect(data).to have_key('title')
    end
  end
end
