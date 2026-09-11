# frozen_string_literal: true

# rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
class CreateLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :leads do |t|
      t.string :url, null: false
      t.string :provider, null: false
      t.string :signature, null: false
      t.string :status, null: false, default: "captured"
      t.datetime :found_at, null: false
      t.jsonb :discovery, null: false, default: {}
      t.string :title
      t.string :company_name
      t.string :location
      t.references :job_posting, foreign_key: true
      t.references :company, foreign_key: true
      t.references :source, foreign_key: true

      t.timestamps
    end

    add_index :leads, :signature, unique: true
    add_index :leads, :status
    add_index :leads, :discovery, using: :gin, opclass: :jsonb_path_ops
  end
end
