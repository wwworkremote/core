# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Charts::Data::JobPostings', type: :request do
  describe 'GET /index' do
    it 'returns http success' do
      get '/charts/data/job_postings.json', headers: { 'Host' => 'localhost' }
      if response.status == 403
        puts "DEBUG: 403 Forbidden Response Body: #{response.body}"
      end
      expect(response).to have_http_status(:success)
    end
  end
end
