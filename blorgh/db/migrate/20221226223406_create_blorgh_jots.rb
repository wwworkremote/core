# frozen_string_literal: true

class CreateBlorghJots < ActiveRecord::Migration[7.0]
  def change
    create_table(:blorgh_jots, id: :uuid) do |t|
      t.string :message, null: false
      t.jsonb :data, default: {}, null: false

      t.datetime 'created_at', precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime 'updated_at', precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end
  end
end
