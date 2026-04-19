class CreatePipelineSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :pipeline_steps do |t|
      t.references :job_posting, null: false, foreign_key: true
      t.string :status
      t.text :notes

      t.timestamps
    end
  end
end
