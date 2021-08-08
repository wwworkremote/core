# frozen_string_literal: true

class RemoveUnusedIndexes < ActiveRecord::Migration[6.1]
  def change
    remove_index :messages, name: 'index_messages_on_created_at'
    remove_index :tag_aliases, name: 'index_tag_aliases_on_tag_id'
    remove_index :pghero_space_stats, name: 'index_pghero_space_stats_on_database_and_captured_at'
    remove_index :friendly_id_slugs, name: 'index_friendly_id_slugs_on_sluggable_type_and_sluggable_id'
  end
end
