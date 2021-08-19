# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JobPosting, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
# Schema version: 20210817230954
#
# Table name: job_postings
#
#  id                 :bigint           not null, primary key
#  body               :string
#  company            :string
#  data               :jsonb            not null
#  location           :string
#  published_at       :datetime
#  signature          :string           not null
#  status             :integer          default("pending")
#  tags               :string           is an Array
#  target_url         :string
#  title              :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  external_author_id :string
#  external_id        :string
#  source_id          :bigint           indexed
#
