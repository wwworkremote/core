# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mission Control - Jobs' do
  let(:email) { ENV.fetch('ADMIN_EMAIL', 'mike@just3ws.com') }
  let(:password) { ENV.fetch('ADMIN_PASSWORD', 'password') }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(email, password) } }

  describe 'GET /mounts/jobs' do
    it 'loads the background jobs dashboard' do
      get '/mounts/jobs', headers: auth_headers
      expect(response).to have_http_status(:success).or have_http_status(:found)

      if response.status == 302
        follow_redirect!
        expect(response).to have_http_status(:success)
      end
    end
  end
end
