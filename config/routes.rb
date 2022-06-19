# frozen_string_literal: true

Rails.application.routes.draw do
  mount HealthBit.rack => '/health'
  mount RailsEventStore::Browser => '/res' if Rails.env.development?
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
