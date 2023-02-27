# frozen_string_literal: true

Rails.application.routes.draw do
  mount Blorgh::Engine => '/blorgh'
end
