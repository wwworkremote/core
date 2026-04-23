# frozen_string_literal: true

# == Schema Information
#
# Table name: system_settings
#
#  id         :bigint           not null, primary key
#  key        :string
#  value      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_system_settings_on_key  (key)
#
require 'rails_helper'

RSpec.describe SystemSetting do
  pending "add some examples to (or delete) #{__FILE__}"
end
