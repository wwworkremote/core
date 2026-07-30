# frozen_string_literal: true

class CreateResumeVersioningAndSkills < ActiveRecord::Migration[7.2]
  def change
    create_skills_table
    create_resumes_table
    create_resume_skills_table
    create_job_searches_table
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def create_skills_table
    create_table :skills do |t|
      t.string :name, null: false
      t.string :category
      t.text :description
      t.vector :embedding, limit: 3584
      t.timestamps
    end
    add_index :skills, :name, unique: true
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def create_resumes_table
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
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # rubocop:disable Metrics/MethodLength
  def create_resume_skills_table
    create_table :resume_skills do |t|
      t.references :resume, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.timestamps
    end
    add_index :resume_skills, %i[resume_id skill_id], unique: true
  end

  def create_job_searches_table
    create_table :job_searches do |t|
      t.references :user, null: false, foreign_key: true
      t.references :resume, foreign_key: true
      t.string :name, null: false
      t.string :status, default: "active", null: false
      t.timestamps
    end
  end
  # rubocop:enable Metrics/MethodLength
end
