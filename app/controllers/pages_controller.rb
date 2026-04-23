# frozen_string_literal: true

class PagesController < ApplicationController
  VALID_PAGES = %w[about].freeze

  def show
    case params[:page]
    when 'about' then render 'pages/about'
    else
      render file: 'public/404.html', status: :not_found, layout: false
    end
  end


  # VALID_PAGES is used for reference
end
