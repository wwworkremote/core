# frozen_string_literal: true

class AddResumePersonaToScenarios < ActiveRecord::Migration[8.1]
  def change
    add_column :scenarios, :resume_persona_id, :string
  end
end
