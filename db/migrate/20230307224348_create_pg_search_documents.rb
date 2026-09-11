# frozen_string_literal: true

class CreatePgSearchDocuments < ActiveRecord::Migration[7.0]
  def up
    create_pg_search_documents_table
  end

  def down
    say_with_time("Dropping table for pg_search multisearch") do
      drop_table :pg_search_documents
    end
  end

  private

  # Vendored verbatim from the pg_search gem's own generator output.
  # rubocop:disable-next Metrics/MethodLength
  def create_pg_search_documents_table
    say_with_time("Creating table for pg_search multisearch") do
      create_table :pg_search_documents do |t|
        t.text :content
        t.belongs_to :searchable, polymorphic: true, index: true
        t.timestamps null: false
      end
    end
  end
end
