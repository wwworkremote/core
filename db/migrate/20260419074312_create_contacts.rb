# frozen_string_literal: true

class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_contacts_table
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def create_contacts_table
    create_table :contacts do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :role
      t.string :relationship_type
      t.references :job_posting, null: false, foreign_key: true

      t.timestamps
    end
  end
  # rubocop:enable Metrics/MethodLength
end
