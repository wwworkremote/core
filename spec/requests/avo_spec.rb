# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Avo Resources', type: :request do
  let(:email) { ENV.fetch('ADMIN_EMAIL', 'mike@just3ws.com') }
  let(:password) { ENV.fetch('ADMIN_PASSWORD', 'password') }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(email, password) } }

  describe 'GET /avo/resources/llm_chats' do
    it 'loads the LLM chats resource page' do
      get '/avo/resources/llm_chats', headers: auth_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'Job Boards Resources' do
    it 'loads job_postings' do
      get '/avo/resources/job_postings', headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it 'loads job_boards_sources' do
      get '/avo/resources/job_boards_sources', headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it 'loads job_boards_queries' do
      get '/avo/resources/job_boards_queries', headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it 'loads job_boards_documents' do
      get '/avo/resources/job_boards_documents', headers: auth_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /avo' do
    it 'loads the Avo dashboard (redirects to first resource)' do
      get '/avo', headers: auth_headers
      expect(response).to have_http_status(:found)
    end
  end
end
