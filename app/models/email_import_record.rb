# frozen_string_literal: true

# == Schema Information
#
# Table name: email_import_records
#
#  id            :bigint           not null, primary key
#  error_message :text
#  file_checksum :string
#  file_path     :string
#  processed_at  :datetime
#  source        :string
#  status        :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  message_id    :string
#
# Indexes
#
#  index_email_import_records_on_file_checksum  (file_checksum) UNIQUE
#  index_email_import_records_on_message_id     (message_id)
#
class EmailImportRecord < ApplicationRecord
  validates :file_checksum, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending processing processed error] }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id message_id file_path source status error_message processed_at created_at updated_at]
  end
end
