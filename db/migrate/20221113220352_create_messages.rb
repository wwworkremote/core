# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table(:messages, id: :bigserial, force: false) do |t|
      t.string :subject, null: false
      t.string :body, null: false
      t.references :user, null: false, type: :uuid

      t.timestamps
    end

    add_index :messages, :subject
  end
end
