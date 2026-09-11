# frozen_string_literal: true

class AddUserToActivity < ActiveRecord::Migration[8.0]
  def change
    add_user_references
    backfill_existing_activity_records
  end

  private

  def add_user_references
    safety_assured do
      add_reference :pipeline_steps, :user, foreign_key: true
      add_reference :contacts, :user, foreign_key: true
      add_reference :company_pipeline_steps, :user, foreign_key: true
    end
  end

  # Assign existing records to the first user if any
  def backfill_existing_activity_records
    reversible do |dir|
      dir.up { backfill_user_id_for_first_user }
    end
  end

  # One cohesive backfill of the same id across 3 tables -- splitting it
  # further would obscure it, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def backfill_user_id_for_first_user
    first_user = User.first
    return unless first_user

    safety_assured do
      execute "UPDATE pipeline_steps SET user_id = #{first_user.id}"
      execute "UPDATE contacts SET user_id = #{first_user.id}"
      execute "UPDATE company_pipeline_steps SET user_id = #{first_user.id}"
    end
  end
end
