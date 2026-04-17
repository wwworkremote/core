# frozen_string_literal: true

class SimplifyUserAuthentication < ActiveRecord::Migration[8.0]
  def change
    # Remove Devise columns (Safety assured for local simplification)
    safety_assured do
      remove_column :users, :encrypted_password, :string, default: '', null: false
      remove_column :users, :reset_password_token, :string
      remove_column :users, :reset_password_sent_at, :datetime
      remove_column :users, :remember_created_at, :datetime
      remove_column :users, :sign_in_count, :integer, default: 0, null: false
      remove_column :users, :current_sign_in_at, :datetime
      remove_column :users, :last_sign_in_at, :datetime
      remove_column :users, :current_sign_in_ip, :string
      remove_column :users, :last_sign_in_ip, :string
      remove_column :users, :confirmation_token, :string
      remove_column :users, :confirmed_at, :datetime
      remove_column :users, :confirmation_sent_at, :datetime
      remove_column :users, :unconfirmed_email, :string
      remove_column :users, :failed_attempts, :integer, default: 0, null: false
      remove_column :users, :unlock_token, :string
      remove_column :users, :locked_at, :datetime
    end

    # Add standard ActiveModel::SecurePassword column
    add_column :users, :password_digest, :string
  end
end
