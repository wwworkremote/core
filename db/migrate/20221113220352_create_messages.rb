# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_messages_table
    add_index :messages, :subject
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def create_messages_table
    create_table(:messages, id: :bigserial, force: false) do |t|
      t.string :subject, null: false
      t.string :body, null: false
      t.references :user, null: false, type: :uuid

      t.timestamps
    end
  end
  # rubocop:enable Metrics/MethodLength
end
