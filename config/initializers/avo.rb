# frozen_string_literal: true

Avo.configure do |config|
  ## == Configuration ==
  # config.root_path = '/avo'
  config.app_name = 'WWWorkRemote'

  config.branding = {
    colors: {
      primary: '#4f46e5' # Indigo 600
    },
    chart_colors: ['#4f46e5', '#0ea5e9', '#10b981', '#f59e0b', '#ef4444']
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
