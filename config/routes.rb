# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  mount Blorgh::Engine, at: '/x'
  mount PgHero::Engine, at: 'pghero'
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount RailsEventStore::Browser => '/res' # if Rails.env.development?
  mount Sidekiq::Web => '/sidekiq'

  devise_for :users

  # resources :users
  resources :messages
  resources :nodes, only: [:index]

  get '/pages/*page' => 'pages#show'

  root 'pages#show', page: 'home'
end
