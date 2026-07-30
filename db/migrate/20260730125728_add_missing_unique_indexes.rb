# frozen_string_literal: true

# Replaces plain indexes backing uniqueness validations with real unique
# indexes -- confirmed zero duplicate rows exist on any of these columns
# before writing this migration, so it's safe to apply as-is.
class AddMissingUniqueIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    replace_with_unique_index(:companies, :slug)
    replace_with_unique_index(:discovery_links, :url)
    replace_with_unique_index(:email_import_records, :file_checksum)
    replace_with_unique_index(:system_settings, :key)
  end

  def down
    replace_with_plain_index(:companies, :slug)
    replace_with_plain_index(:discovery_links, :url)
    replace_with_plain_index(:email_import_records, :file_checksum)
    replace_with_plain_index(:system_settings, :key)
  end

  private

  def replace_with_unique_index(table, column)
    remove_index table, column, algorithm: :concurrently
    add_index table, column, unique: true, algorithm: :concurrently
  end

  def replace_with_plain_index(table, column)
    remove_index table, column, algorithm: :concurrently
    add_index table, column, algorithm: :concurrently
  end
end
