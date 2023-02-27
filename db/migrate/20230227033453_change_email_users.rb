# frozen_string_literal: true

class ChangeEmailUsers < ActiveRecord::Migration[7.0]
  def change
    change_column :users, :email, :string, default: ''
  end
end
