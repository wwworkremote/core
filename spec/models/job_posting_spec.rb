# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JobPosting, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: job_postings
#
#  id                 :bigint           not null, primary key
#  signature          :string           not null
#  status             :integer          default("pending")
#  source_id          :bigint
#  title              :string
#  body               :string
#  company            :string
#  location           :string
#  external_author_id :string
#  external_id        :string
#  published_at       :datetime
#  tags               :string           is an Array
#  target_url         :string
#  data               :jsonb            not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
