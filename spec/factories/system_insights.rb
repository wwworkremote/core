# frozen_string_literal: true

# == Schema Information
#
# Table name: system_insights
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE)
#  context     :text
#  embedding   :vector(3584)
#  file_path   :string
#  line_number :integer
#  message     :text
#  severity    :integer
#  tool        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_system_insights_on_active     (active)
#  index_system_insights_on_file_path  (file_path)
#
FactoryBot.define do
  factory :system_insight do
    tool { :rubocop }
    severity { :warning }
    message { "RuboCop offense found" }
    file_path { "app/models/user.rb" }
    line_number { 10 }
    active { true }
  end
end
