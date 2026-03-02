# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Workable::Fetcher, type: :service do
  let(:service) { described_class.new(subdomain: 'test-sub', token: 'test-token') }
  let(:source) { JobBoards::Source.find_or_create_by!(slug: 'workable', name: 'Workable') }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }

  describe '#call' do
    before do
      source
      query
      stub_request(:get, /test-sub.workable.com/)
        .to_return(status: 200, body: {
          jobs: [
            { shortcode: 'abc', title: 'Workable Dev', state: 'published' }
          ]
        }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'fetches JSON jobs and stores them as documents' do
      expect {
        service.call
      }.to change(JobBoards::Document, :count).by(1)

      doc = JobBoards::Document.last
      data = JSON.parse(doc.document)
      
      expect(doc.source_id).to eq(source.id)
      expect(data).to have_key('shortcode')
      expect(data).to have_key('title')
    end
  end
end
