# frozen_string_literal: true

# == Schema Information
#
# Table name: sources
#
#  id         :bigint           not null, primary key
#  event      :jsonb            not null
#  payload    :jsonb            not null
#  signature  :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  origin_id  :bigint
#
# Indexes
#
#  index_sources_on_event      (event) USING gin
#  index_sources_on_origin_id  (origin_id)
#  index_sources_on_payload    (payload) USING gin
#  index_sources_on_signature  (signature) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (origin_id => origins.id)
#
require "rails_helper"

RSpec.describe Source do
  describe "associations" do
    it "belongs to origin" do
      association = described_class.reflect_on_association(:origin)
      expect(association.macro).to eq :belongs_to
    end

    it "has many job_postings" do
      association = described_class.reflect_on_association(:job_postings)
      expect(association.macro).to eq :has_many
    end
  end
end
