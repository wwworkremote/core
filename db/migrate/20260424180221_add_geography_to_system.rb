# frozen_string_literal: true

class AddGeographyToSystem < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :job_postings, :country_code, :string unless column_exists?(:job_postings, :country_code)
    add_column :users, :preferred_countries, :text, array: true, default: [] unless column_exists?(:users,
                                                                                                   :preferred_countries)

    add_index :job_postings, :country_code, algorithm: :concurrently unless index_exists?(:job_postings, :country_code)
  end
end
