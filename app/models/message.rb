# == Schema Information
#
# Table name: messages
#
#  id         :bigint           not null, primary key
#  body       :string           not null
#  subject    :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_messages_on_subject  (subject)
#  index_messages_on_user_id  (user_id)
#
class Message < ApplicationRecord
  belongs_to :user
end
