# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: guided_session_replays
#
#  id                :bigint           not null, primary key
#  allow_real_site   :boolean          default(FALSE), not null
#  current_step      :integer          default(0), not null
#  ended_at          :datetime
#  ended_reason      :string
#  started_at        :datetime         not null
#  status            :string           default("running"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  guided_session_id :bigint           not null
#
# Indexes
#
#  index_guided_session_replays_on_guided_session_id             (guided_session_id)
#  index_guided_session_replays_on_guided_session_id_and_status  (guided_session_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (guided_session_id => guided_sessions.id)
#
RSpec.describe GuidedSessionReplay do
  let(:session) do
    GuidedSession.create!(source_url: "https://wwworkremote.localhost/x", purpose: "application_execution",
                          status: "completed")
  end

  it "tracks its own lifecycle" do
    replay = session.guided_session_replays.create!

    expect(replay).to be_active
    replay.update!(status: "completed")
    expect(replay).to be_ended
  end

  # TASK-133 AC#3/#4 / Bounded Agency: no replay code path emits a click,
  # navigate, or submit -- it only ever fills.
  it "has no replay code that clicks, navigates, or submits" do
    offenders = Rails.root.glob("app/**/*replay*.rb").select do |path|
      path.read.match?(/\.click|navigate_to|submit!|press\(|dispatchEvent|\.submit\b/)
    end

    expect(offenders).to be_empty
  end
end
