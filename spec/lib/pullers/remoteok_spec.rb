# frozen_string_literal: true

require 'rails_helper'

module Pullers
  RSpec.describe RemoteOK, vcr: true do
    describe '.jobs' do
      it do
        ap described_class.jobs
      end
    end

    describe '.client' do
    end
  end
end
