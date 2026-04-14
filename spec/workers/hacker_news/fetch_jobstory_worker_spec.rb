# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HackerNews::FetchJobstoryWorker, type: :worker do
  let(:worker) { described_class.new }
  let(:jobstory_id) { 47183907 }
  let(:source) { JobBoards::Source.create!(name: 'HackerNews', slug: 'hackernews') }
  let(:query) { JobBoards::Query.create!(source_id: source.id) }

  describe '#perform', vcr: { cassette_name: 'hn_jobstory' } do
    it 'fetches and saves a job story' do
      expect {
        worker.perform(jobstory_id, source.id, query.id)
      }.to change(JobBoards::Document, :count).by(1)

      doc = JobBoards::Document.find_by!(signature: Digest::SHA256.hexdigest("hn-#{jobstory_id}"))
      expect(doc.source_id).to eq(source.id)
      expect(JSON.parse(doc.document)['title']).to include('Kyber')
    end

    it 'skips if jobstory already exists' do
      JobBoards::Document.create!(
        signature: Digest::SHA256.hexdigest("hn-#{jobstory_id}"),
        source_id: source.id,
        job_boards_query_id: query.id,
        document: { title: 'Old' }.to_json
      )
      
      expect {
        worker.perform(jobstory_id, source.id, query.id)
      }.not_to change(JobBoards::Document, :count)
    end
  end
end
