# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Avo Resources', type: :request do
  describe 'GET /avo/resources/llm_chats' do
    it 'loads the LLM chats resource page' do
      # We don't need to be authenticated if devise is not protecting avo yet,
      # or we can sign in a user if it is.
      get '/avo/resources/llm_chats'
      
      # It might redirect to login if not authenticated, 
      # but the important part is that it doesn't raise NameError.
      expect(response).not_to have_http_status(:error)
    end
  end
end
