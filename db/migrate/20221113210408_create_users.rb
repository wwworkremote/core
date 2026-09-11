# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_users_table
    add_index :users, :slug, unique: true
    add_index :users, :email, unique: true
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def create_users_table
    create_table(:users, id: :bigserial, force: false) do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :email, null: false

      t.timestamps
    end
  end
end
