# frozen_string_literal: true

require 'rails_helper'

module Pullers
  RSpec.describe HackerNews, vcr: true do
    describe '.jobs' do
      subject(:jobs) { described_class.pull }

      before { jobs }

      it { is_expected.to be_an(Array) }
      it { is_expected.not_to be_empty }
      it { is_expected.to all(be_a(Hash)) }

      it { is_expected.to all(include('by')) }
      it { is_expected.to all(include('id')) }
      it { is_expected.to all(include('score')) }
      it { is_expected.to all(include('time')) }
      it { is_expected.to all(include('title')) }
      it { is_expected.to all(include('type')) }
    end
  end
end
