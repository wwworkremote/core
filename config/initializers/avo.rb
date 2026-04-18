# frozen_string_literal: true

Avo.configure do |config|
  ## == Configuration ==
  config.home_path = -> { '/avo/resources/job_postings' }
  config.app_name = 'WWWorkRemote'

  config.branding = {
    colors: {
      background: '34 33 44', # Dracula bg (#22212C)
      surface: '23 22 29',    # Dracula bg_dark (#17161D)
      primary: '149 128 255'  # Dracula purple (#9580FF)
    },
    chart_colors: ['#9580FF', '#80FFEA', '#8AFF80', '#FFCA80', '#FF9580']
  }

  ## == Authentication ==
  config.current_user_method = :current_user

  config.main_menu = lambda {
    section 'WwworkRemote', icon: 'heroicons/outline/briefcase' do
      resource :job_posting
    end

    section 'Job Boards (Raw)', icon: 'heroicons/outline/server-stack' do
      resource :job_boards_source
      resource :job_boards_query
    end

    section 'WwworkRemote', icon: 'heroicons/outline/cpu-chip' do
      resource :llm_chat
      resource :llm_message
      resource :tool_call
    end

    section 'Tools', icon: 'heroicons/outline/wrench' do
      all_tools
    end
  }

  # Set the context for Avo
  config.context = lambda { |*|
    {
      current_user: current_user
    }
  }
end

Rails.configuration.to_prepare do
  Avo::BaseController.include Authenticatable
  Avo::ApplicationController.include Authenticatable
end
