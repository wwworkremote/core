# frozen_string_literal: true

class ChangeEmailUsers < ActiveRecord::Migration[7.0]
  def up
    change_column :users, :email, :string, default: ""
  end

  def down
    change_column :users, :email, :string, default: nil
  end
end
