class CreateSystemInsights < ActiveRecord::Migration[8.0]
  def change
    create_table :system_insights do |t|
      t.integer :tool
      t.integer :severity
      t.text :message
      t.string :file_path
      t.integer :line_number
      t.text :context
      t.boolean :active, default: true
      t.vector :embedding, limit: 3584

      t.timestamps
    end

    add_index :system_insights, :file_path
    add_index :system_insights, :active
  end
end
