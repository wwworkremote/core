# frozen_string_literal: true

Rails.application.routes.draw do
  resources :llm_chats do
    resources :llm_messages, only: %i[create]
  end
  resources :models, only: %i[index show] do
    collection do
      post :refresh
    end
  end
  mount_avo
  # Dashboard Routes
  root to: 'home#index'
  get 'home/index'

  resources :outbound_links, only: [:show]
  resources :job_postings, only: %i[index show]

  resources :data_fetchers, only: [:index] do
    collection do
      post :run
      post :audit
    end
  end

  namespace :api, defaults: { format: :json }, constraints: { format: :json } do
    namespace :v0 do
      resources :sources, only: %i[index show]
      resources :job_postings, only: %i[index show]
    end
  end

  namespace :charts do
    namespace :data, defaults: { format: :json }, constraints: { format: :json } do
      get 'sources' => 'sources#index'
      get 'job_postings' => 'job_postings#index'
      get 'job_postings/corpus'
    end
  end

  mount PgHero::Engine, at: 'pghero'
  mount MissionControl::Jobs::Engine, at: '/jobs'
  get '/pages/*page' => 'pages#show'
end
