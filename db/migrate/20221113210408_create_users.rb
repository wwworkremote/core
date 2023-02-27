# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table(:users, id: :bigserial, force: false) do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :email, null: false, default: ''

      t.timestamps
    end

    add_index :users, :slug, unique: true
    add_index :users, :email, unique: true
  end
end
