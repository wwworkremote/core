# frozen_string_literal: true

class AddSkillsToWorkExperiences < ActiveRecord::Migration[8.1]
  def change
    add_column :work_experiences, :skills, :text
  end
end
