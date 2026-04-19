class AddFieldsToPipelineSteps < ActiveRecord::Migration[8.0]
  def change
    add_column :pipeline_steps, :link, :string
    add_column :pipeline_steps, :note, :text
  end
end
