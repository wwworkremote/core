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
#  index_email_import_records_on_file_checksum  (file_checksum)
#  index_email_import_records_on_message_id     (message_id)
#
FactoryBot.define do
  factory :email_import_record do
    sequence(:file_checksum) { |n| "checksum-#{n}" }
    file_path { "/tmp/test.eml" }
    source { "indeed" }
    status { "pending" }
  end
end
