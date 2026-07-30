# frozen_string_literal: true

class AddCoordinatesToJobPostings < ActiveRecord::Migration[8.0]
  def change
    change_table :job_postings, bulk: true do |t|
      t.float :latitude
      t.float :longitude
    end
  end
end
