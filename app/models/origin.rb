# frozen_string_literal: true

class Origin < ApplicationRecord
end

# == Schema Information
#
# Table name: origins
#
#  id         :bigint           not null, primary key
#  name       :citext
#  data       :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
