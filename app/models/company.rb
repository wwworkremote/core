# frozen_string_literal: true

# == Schema Information
#
# Table name: companies
#
#  id                 :bigint           not null, primary key
#  disposition        :string
#  glassdoor_data     :jsonb
#  ingestion_enabled  :boolean          default(TRUE), not null
#  name               :string
#  sentiment_score    :float
#  slug               :string
#  status             :string
#  toxic_culture_flag :boolean
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_companies_on_name  (name) UNIQUE
#  index_companies_on_slug  (slug)
#
class Company < ApplicationRecord
  include AASM

  has_many :company_pipeline_steps, dependent: :destroy
  has_many :job_postings, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  aasm column: :status do
    state :none, initial: true
    state :favorited, :archived

    event :favorite do
      transitions from: %i[none archived], to: :favorited
    end

    event :archive do
      transitions from: [:favorited], to: :archived
    end
  end

  def add_pipeline_note(note, link: nil)
    company_pipeline_steps.create!(status: 'noted', note: note, link: link)
  end
end
