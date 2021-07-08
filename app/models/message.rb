# frozen_string_literal: true

class Message < ApplicationRecord
  enum status: {
    pending: 0,
    active: 1,
    archive: 2
  }, _prefix: true
end
