# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Distributed Circuit Breaker Integration' do
  include ApiGuard

  let(:source_slug) { 'lever' }
  let!(:source) { JobBoards::Source.find_or_create_by!(slug: source_slug, name: 'Lever') }
  let!(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }

  before do
    Rails.cache.clear
  end

  it 'trips the circuit breaker on a 429 response' do
    # Mock a 429 response
    stub_request(:get, /api.lever.co/).to_return(status: 429, headers: { 'Retry-After' => '60' })

    client = JobBoards::Client.new(source_slug)

    # Directly test the helper first
    lock_source!(source_slug, duration: 10.seconds)
    expect(source_locked?(source_slug)).to be true
    Rails.cache.delete("api_guard:#{source_slug}:locked_until")

    # Now test via the client
    response = client.get('https://api.lever.co/v0/postings/test')
    expect(response).to be_nil
    expect(source_locked?(source_slug)).to be true
  end

  it 'gracefully skips execution in a granular job when the circuit is open' do
    # Manually lock the source
    lock_source!(source_slug, duration: 1.minute)

    # Mock a successful response (should NOT be called)
    stub_request(:get, /api.lever.co/).to_return(status: 200, body: [].to_json)

    # Execute the granular fetch job
    job = JobBoards::GranularFetchJob.new

    # It should return early because the source is locked
    # We can verify this by checking that no logs were produced for fetching
    expect(Rails.logger).not_to receive(:info).with(/Lever: Fetched jobs/)

    job.perform('Lever::Fetcher', 'test-site', '', source.id, query.id)
  end

  it 'does not affect other sources when one is locked' do
    lock_source!(source_slug, duration: 1.minute)

    other_slug = 'remotive'
    expect(source_locked?(other_slug)).to be false
  end

  it 'trips the circuit breaker for geocoding on a 429 error' do
    # Mock a Geocoder 429 error (simulating always_raise: :all behavior)
    allow(Geocoder).to receive(:search).and_raise(StandardError.new('Geocoding API error: 429 Too Many Requests'))

    job_posting = JobPosting.create!(signature: 'geo-test', location: 'New York', title: 'Test', company: 'Test')

    job = JobBoards::GeocodingJob.new
    expect {
      job.perform(job_posting.id)
    }.to change { source_locked?('geocoding') }.from(false).to(true)
  end
end
