# frozen_string_literal: true

class CreatePipelineSteps < ActiveRecord::Migration[8.0]
  def change
    create_pipeline_steps_table
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def create_pipeline_steps_table
    create_table :pipeline_steps do |t|
      t.references :job_posting, null: false, foreign_key: true
      t.string :status
      t.text :notes

      t.timestamps
    end
  end
end
