# frozen_string_literal: true

class PagesController < ApplicationController
  VALID_PAGES = %w[about contact help terms privacy].freeze

  def show
    case params[:page]
    when 'about'   then render 'pages/about'
    when 'contact' then render 'pages/contact'
    when 'help'    then render 'pages/help'
    when 'terms'   then render 'pages/terms'
    when 'privacy' then render 'pages/privacy'
    else
      render file: 'public/404.html', status: :not_found, layout: false
    end
  end

  private

  # VALID_PAGES is used for reference
end
