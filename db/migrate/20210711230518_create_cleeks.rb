# frozen_string_literal: true

class CreateCleeks < ActiveRecord::Migration[6.1]
  def change
    create_view :cleeks
  end
end
