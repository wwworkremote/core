# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HackerNews::FetchJobstoryWorker, type: :worker do
  let(:worker) { described_class.new }
  let(:jobstory_id) { 47183907 }

  describe '#perform', vcr: { cassette_name: 'hn_jobstory' } do
    it 'fetches and saves a job story' do
      expect {
        worker.perform(jobstory_id)
      }.to change(HackerNews::V0::Jobstory, :count).by(1)

      jobstory = HackerNews::V0::Jobstory.find(jobstory_id)
      expect(jobstory.title).to include('Kyber')
      expect(jobstory.by).to eq('asontha')
    end

    it 'skips if jobstory already exists' do
      HackerNews::V0::Jobstory.create!(id: jobstory_id, data: { test: true })
      
      expect {
        worker.perform(jobstory_id)
      }.not_to change(HackerNews::V0::Jobstory, :count)
    end
  end
end
