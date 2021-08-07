# frozen_string_literal: true

class RemoveUnneededIndexes < ActiveRecord::Migration[6.1]
  def change
    remove_index :friendly_id_slugs,
                 name: 'index_friendly_id_slugs_on_slug_and_sluggable_type',
                 column: %i[slug sluggable_type]
  end
end
