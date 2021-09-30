# frozen_string_literal: true

require 'rails_helper'

module Pullers
  RSpec.describe Monster, vcr: true do
    describe '.jobs' do
      subject(:jobs) { described_class.pull }

      before { jobs }

      it { is_expected.to be_an(Array) }
      it { is_expected.not_to be_empty }
      it { is_expected.to all(be_a(Hash)) }

      it { is_expected.to all(include('description')) }
      it { is_expected.to all(include('guid')) }
      it { is_expected.to all(include('link')) }
      it { is_expected.to all(include('pubDate')) }
      it { is_expected.to all(include('title')) }
    end
  end
end
