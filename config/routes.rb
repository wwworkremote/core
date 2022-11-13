# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  resources :users
  resources :messages
  mount RailsEventStore::Browser => '/res' # if Rails.env.development?
  mount Sidekiq::Web => '/sidekiq'
  mount PgHero::Engine, at: 'pghero'

  resources :nodes, only: [:index]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
