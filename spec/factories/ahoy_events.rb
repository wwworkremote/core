# frozen_string_literal: true

FactoryBot.define do
  factory :ahoy_event, class: "Ahoy::Event" do
    visit factory: %i[ahoy_visit]
    name { "Captured Lead" }
    time { Time.current }
    properties { {} }
  end
end
