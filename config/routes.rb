# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  mount_avo
  # Dashboard Routes
  root to: 'home#index'
  get 'home/index'

  resources :job_postings, only: %i[index show]

  resources :data_fetchers, only: [:index] do
    collection do
      post :run
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

  # Core / Data Acquisition Routes
  get 'dice/roll'
  put 'hacker_news/fetch_jobstory'

  mount PgHero::Engine, at: 'pghero'
  # mount Blorgh::Engine, at: '/x'

  mount Sidekiq::Web => '/sidekiq'

  devise_for :users
  resources :messages
  resources :nodes, only: [:index]
  get '/pages/*page' => 'pages#show'
end
