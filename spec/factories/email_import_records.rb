# frozen_string_literal: true

FactoryBot.define do
  factory :email_import_record do
    sequence(:file_checksum) { |n| "checksum-#{n}" }
    file_path { "/tmp/test.eml" }
    source { "indeed" }
    status { "pending" }
  end
end
