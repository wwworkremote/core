# frozen_string_literal: true

class AddDashboardTablesToCore < ActiveRecord::Migration[7.1]
  def change
    # Extensions (already mostly enabled in core/db/migrate/20220728223111_enable_extensions.rb)
    # But ensuring citext for dashboard columns
    enable_extension 'citext' unless extension_enabled?('citext')

    create_table :origins do |t|
      t.citext :name
      t.jsonb :data, default: {}, null: false
      t.timestamps
    end

    create_table :sources do |t|
      t.string :signature, null: false
      t.jsonb :event, default: {}, null: false
      t.jsonb :payload, default: {}, null: false
      t.references :origin, foreign_key: true
      t.timestamps
    end
    add_index :sources, :signature, unique: true

    create_table :job_postings do |t|
      t.string :signature, null: false
      t.references :source, foreign_key: true
      t.string :title
      t.string :body
      t.string :company
      t.string :location
      t.string :external_author_id
      t.string :external_id
      t.datetime :published_at
      t.string :tags, array: true
      t.string :target_url
      t.jsonb :data, default: {}, null: false
      t.timestamps
    end

    create_table :domains do |t|
      t.citext :name, null: false
      t.bigint :root_domain_id
      t.timestamps
    end
    add_index :domains, :name, unique: true

    create_table :target_domains do |t|
      t.references :job_posting, null: false, foreign_key: true
      t.references :domain, null: false, foreign_key: true
      t.timestamps
    end
    add_index :target_domains, %i[domain_id job_posting_id], unique: true
    add_index :target_domains, %i[job_posting_id domain_id], unique: true

    create_table :emails do |t|
      t.citext :address, null: false
      t.timestamps
    end
    add_index :emails, :address, unique: true
  end
end
