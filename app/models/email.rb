# frozen_string_literal: true

class Email < ApplicationRecord
end

# == Schema Information
#
# Table name: emails
#
#  id         :bigint           not null, primary key
#  address    :citext           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_emails_on_address  (address) UNIQUE
#
