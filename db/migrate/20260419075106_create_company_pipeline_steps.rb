class CreateCompanyPipelineSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :company_pipeline_steps do |t|
      t.references :company, null: false, foreign_key: true
      t.string :status
      t.text :note
      t.string :link

      t.timestamps
    end
  end
end
