class AddExternalIdToWorkExperiences < ActiveRecord::Migration[8.0]
  def change
    add_column :work_experiences, :external_id, :string
    safety_assured { add_index :work_experiences, :external_id }
  end
end
