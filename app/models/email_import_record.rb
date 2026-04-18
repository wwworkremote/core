# frozen_string_literal: true

class EmailImportRecord < ApplicationRecord
  validates :file_checksum, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending processing processed error] }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id message_id file_path source status error_message processed_at created_at updated_at]
  end
end
