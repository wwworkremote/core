# == Schema Information
#
# Table name: companies
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  status     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_companies_on_slug  (slug)
#
class Company < ApplicationRecord
  include AASM

  has_many :company_pipeline_steps, dependent: :destroy
  has_many :job_postings, dependent: :nullify

  aasm column: :status do
    state :none, initial: true
    state :favorited, :archived

    event :favorite do
      transitions from: [:none, :archived], to: :favorited
    end

    event :archive do
      transitions from: [:favorited], to: :archived
    end
  end

  def add_pipeline_note(note, link: nil)
    company_pipeline_steps.create!(status: 'noted', note: note, link: link)
  end
end
