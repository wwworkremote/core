# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/throttled/web'

Rails.application.routes.draw do
  get 'dice/roll'
  put 'hacker_news/fetch_jobstory'

  mount PgHero::Engine, at: 'pghero'

  mount Blorgh::Engine, at: '/x'

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  mount RailsEventStore::Browser => '/res' # if Rails.env.development?

  Sidekiq::Throttled::Web.enhance_queues_tab!
  mount Sidekiq::Web => '/sidekiq'

  devise_for :users

  resources :messages
  resources :nodes, only: [:index]

  get '/pages/*page' => 'pages#show'

  root 'pages#show', page: 'home'
end
