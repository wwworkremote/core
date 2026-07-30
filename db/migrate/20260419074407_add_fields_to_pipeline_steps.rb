# frozen_string_literal: true

class AddFieldsToPipelineSteps < ActiveRecord::Migration[8.0]
  def change
    change_table :pipeline_steps, bulk: true do |t|
      t.string :link
      t.text :note
    end
  end
end
