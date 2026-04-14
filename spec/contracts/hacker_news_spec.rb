# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HackerNews Live Contract', type: :request do
  it 'fetches valid jobstory IDs from HackerNews', :live do
    VCR.turned_off do
      WebMock.allow_net_connect!
      
      response = Faraday.get('https://hacker-news.firebaseio.com/v0/jobstories.json')
      expect(response.status).to eq(200)
      
      ids = JSON.parse(response.body)
      expect(ids).to be_an(Array)
      expect(ids).not_to be_empty
      
      # Fetch first item to verify structure
      item_id = ids.first
      item_response = Faraday.get("https://hacker-news.firebaseio.com/v0/item/#{item_id}.json")
      expect(item_response.status).to eq(200)
      
      item = JSON.parse(item_response.body)
      expect(item['id']).to eq(item_id)
      expect(item['type']).to eq('job')
      expect(item['title']).to be_present
      
      WebMock.disable_net_connect!
    end
  end
end
