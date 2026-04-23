# frozen_string_literal: true

require 'rails_helper'

# Live system spec — requires a running llama.cpp server and real browser.
# Excluded from the normal suite. Run explicitly:
#   bundle exec rspec spec/system/llm_chat_automation_spec.rb --tag live
RSpec.describe 'LLM Chat Automation', :js, :live do
  before do
    driven_by :cuprite
  end

  it 'completes a chat loop with the local model' do
    # 1. Initiate chat
    visit '/llm_chats/new'

    # Model name matches config/models.yml name field for the primary profile
    select 'Qwen 2.5 Coder 7B (Local)', from: 'llm_chat[model_id]'

    fill_in 'llm_chat[prompt]', with: "What's the best thing about AI?"
    click_button 'Establish Neural Link'

    # Verify redirection to chat
    expect(page).to have_content('Neural link established.')

    # 2. Wait for assistant response (streamed)
    expect(page).to have_css('.chat-start .chat-bubble', wait: 30)

    # 3. Follow up
    fill_in 'Describe your objective...', with: 'Give me a single-sentence answer.'
    click_button 'Send'

    expect(page).to have_css('.chat-start .chat-bubble', count: 2, wait: 30)

    # 4. Third interaction
    fill_in 'Describe your objective...', with: 'Summarize that in one word.'
    click_button 'Send'

    expect(page).to have_css('.chat-start .chat-bubble', count: 3, wait: 30)
  end
end
