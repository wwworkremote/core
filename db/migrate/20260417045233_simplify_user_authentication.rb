# frozen_string_literal: true

class SimplifyUserAuthentication < ActiveRecord::Migration[8.0]
  def change
    remove_devise_columns
    add_column :users, :password_digest, :string
  end

  private

  # One cohesive list of Devise columns being removed -- splitting it
  # further would obscure it, not simplify it.
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def remove_devise_columns
    safety_assured do
      remove_column :users, :encrypted_password, :string, default: "", null: false
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
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
