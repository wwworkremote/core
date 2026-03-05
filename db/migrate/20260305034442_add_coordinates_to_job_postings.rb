# frozen_string_literal: true

class AddCoordinatesToJobPostings < ActiveRecord::Migration[8.0]
  def change
    add_column :job_postings, :latitude, :float
    add_column :job_postings, :longitude, :float
  end
end
