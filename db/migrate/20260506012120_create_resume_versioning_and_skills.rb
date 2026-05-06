# frozen_string_literal: true

class CreateResumeVersioningAndSkills < ActiveRecord::Migration[7.2]
  def change
    create_table :skills do |t|
      t.string :name, null: false
      t.string :category
      t.text :description
      t.vector :embedding, limit: 3584
      t.timestamps
    end
    add_index :skills, :name, unique: true

    create_table :resumes do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint :parent_id
      t.string :name, null: false
      t.integer :version, default: 1, null: false
      t.string :status, default: "inactive", null: false
      t.jsonb :content, default: {}, null: false
      t.vector :embedding, limit: 3584
      t.string :imported_from_url
      t.timestamps
    end
    add_index :resumes, :parent_id
    add_index :resumes, %i[user_id name version], unique: true

    create_table :resume_skills do |t|
      t.references :resume, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.timestamps
    end
    add_index :resume_skills, %i[resume_id skill_id], unique: true

    create_table :job_searches do |t|
      t.references :user, null: false, foreign_key: true
      t.references :resume, foreign_key: true
      t.string :name, null: false
      t.string :status, default: "active", null: false
      t.timestamps
    end
  end
end
