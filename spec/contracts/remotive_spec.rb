# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Remotive Live Contract', type: :request do
  it 'fetches a valid JSON response from Remotive', :live do
    VCR.turned_off do
      WebMock.allow_net_connect!
      
      conn = Faraday.new(url: 'https://remotive.com') do |f|
        f.options.timeout = 120
        f.options.open_timeout = 60
      end

      response = conn.get('/api/remote-jobs?limit=5')
      expect(response.status).to eq(200)
      
      data = JSON.parse(response.body)
      expect(data['jobs']).not_to be_empty
      
      job = data['jobs'].first
      expect(job['id']).to be_present
      expect(job['title']).to be_present
      expect(job['url']).to be_present
      
      WebMock.disable_net_connect!
    end
  end
end
