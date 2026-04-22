# frozen_string_literal: true

class AddUserToActivity < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      add_reference :pipeline_steps, :user, foreign_key: true
      add_reference :contacts, :user, foreign_key: true
      add_reference :company_pipeline_steps, :user, foreign_key: true
    end

    # Assign existing records to the first user if any
    reversible do |dir|
      dir.up do
        first_user = User.first
        if first_user
          safety_assured do
            execute "UPDATE pipeline_steps SET user_id = #{first_user.id}"
            execute "UPDATE contacts SET user_id = #{first_user.id}"
            execute "UPDATE company_pipeline_steps SET user_id = #{first_user.id}"
          end
        end
      end
    end
  end
end
