# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  resources :users
  resources :messages

  mount RailsEventStore::Browser => '/res' # if Rails.env.development?
  mount Sidekiq::Web => '/sidekiq'
  mount PgHero::Engine, at: 'pghero'
  mount Blorgh::Engine, at: '/x'

  get '/pages/:page' => 'pages#show'

  resources :nodes, only: [:index]

  root 'pages#show', page: 'home'
end
