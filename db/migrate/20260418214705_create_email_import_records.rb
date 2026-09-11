# frozen_string_literal: true

class CreateEmailImportRecords < ActiveRecord::Migration[8.0]
  def change
    create_email_import_records_table
    add_index :email_import_records, :message_id
    add_index :email_import_records, :file_checksum
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def create_email_import_records_table
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
  end
end
