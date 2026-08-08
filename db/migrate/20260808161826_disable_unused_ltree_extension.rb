# frozen_string_literal: true

class DisableUnusedLtreeExtension < ActiveRecord::Migration[8.1]
  def change
    disable_extension "ltree"
  end
end
