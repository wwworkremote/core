# frozen_string_literal: true

class CreateEmailImportRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :email_import_records do |t|
      t.string :message_id
      t.string :file_path
      t.string :file_checksum
      t.string :source
      t.string :status
      t.text :error_message
      t.datetime :processed_at

      t.timestamps
    end
    add_index :email_import_records, :message_id
    add_index :email_import_records, :file_checksum
  end
end
