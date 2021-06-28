# frozen_string_literal: true

require 'rails_helper'

module HackerNews
  module V0
    RSpec.describe Jobstories do
      it 'cool', :vcr do
        ap described_class.new.call
      end
    end
  end
end
