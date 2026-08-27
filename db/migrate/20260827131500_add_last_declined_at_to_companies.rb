# frozen_string_literal: true

class AddLastDeclinedAtToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :last_declined_at, :datetime
  end
end
