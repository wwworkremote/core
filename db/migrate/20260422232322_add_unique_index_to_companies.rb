class AddUniqueIndexToCompanies < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    safety_assured { execute "SET lock_timeout = '30s'" }
    add_index :companies, :name, unique: true, algorithm: :concurrently, if_not_exists: true
  end
end
