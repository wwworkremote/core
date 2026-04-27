# frozen_string_literal: true

# == Schema Information
#
# Table name: board_queries
#
#  id           :bigint           not null, primary key
#  board_name   :string
#  priority     :integer
#  query_params :json
#  remote       :boolean
#  terms        :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
FactoryBot.define do
  factory :board_query do
    board_name { "indeed" }
    terms { ["Ruby"] }
    remote { true }
    priority { 1 }
    query_params { { "remote" => true } }
  end
end
