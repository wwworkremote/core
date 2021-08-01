# frozen_string_literal: true

require 'rails_helper'

module Pullers
  module HackerNews
    module V0
      RSpec.describe Jobstories do
        it 'requests a list of jobstories', :vcr do
          puts described_class.new.call.inspect
        end
      end
    end
  end
end
