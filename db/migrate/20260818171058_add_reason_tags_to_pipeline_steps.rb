# frozen_string_literal: true

class AddReasonTagsToPipelineSteps < ActiveRecord::Migration[8.1]
  def change
    add_column :pipeline_steps, :reason_tags, :jsonb, default: {}, null: false
  end
end
