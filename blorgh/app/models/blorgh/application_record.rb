# frozen_string_literal: true

module Blorgh
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
