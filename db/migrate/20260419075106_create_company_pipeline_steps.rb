# frozen_string_literal: true

class CreateCompanyPipelineSteps < ActiveRecord::Migration[8.0]
  def change
    create_company_pipeline_steps_table
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def create_company_pipeline_steps_table
    create_table :company_pipeline_steps do |t|
      t.references :company, null: false, foreign_key: true
      t.string :status
      t.text :note
      t.string :link

      t.timestamps
    end
  end
  # rubocop:enable Metrics/MethodLength
end
