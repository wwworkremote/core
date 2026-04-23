# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'RubyLLM Chat Interface' do
  let(:email) { ENV.fetch('ADMIN_EMAIL', 'mike@just3ws.com') }
  let(:password) { ENV.fetch('ADMIN_PASSWORD', 'password') }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(email, password) } }

  describe 'GET /llm_chats' do
    it 'loads the LLM chats index page' do
      get '/llm_chats', headers: auth_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /llm_chats/new' do
    it 'loads the new LLM chat page' do
      get '/llm_chats/new', headers: auth_headers
      expect(response).to have_http_status(:ok)
    end
  end
end
