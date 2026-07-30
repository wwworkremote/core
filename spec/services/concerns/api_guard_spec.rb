# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiGuard do
  let(:test_class) do
    Class.new do
      include ApiGuard
    end
  end
  let(:instance) { test_class.new }
  let(:slug) { "test-source" }

  before do
    Rails.cache.clear
  end

  describe "#lock_source!" do
    it "locks the source for a specified duration" do
      instance.lock_source!(slug, duration: 10.minutes)
      expect(instance.source_locked?(slug)).to be true
    end
  end

  describe "#source_locked?" do
    it "returns false if not locked" do
      expect(instance.source_locked?(slug)).to be false
    end

    it "returns false after lock expires" do
      instance.lock_source!(slug, duration: 1.second)
      sleep 1.1
      expect(instance.source_locked?(slug)).to be false
    end
  end

  describe "#unlock_source!" do
    it "removes the lock" do
      instance.lock_source!(slug)
      instance.unlock_source!(slug)
      expect(instance.source_locked?(slug)).to be false
    end
  end

  describe "#with_api_guard" do
    let!(:source) { JobBoards::Source.create!(slug: slug, name: "Test") }

    it "aborts if locked" do
      instance.lock_source!(slug)
      result = instance.with_api_guard(slug) { :executed }
      expect(result).to eq(:locked)
    end

    it "respects cooldown" do
      instance.with_api_guard(slug) { :executed }
      result = instance.with_api_guard(slug) { :executed }
      expect(result).to eq(:cooldown)
    end

    it "bypasses cooldown if forced" do
      instance.with_api_guard(slug) { :executed }
      result = instance.with_api_guard(slug, force: true) { :executed }
      expect(result).to be true
    end

    it "returns :missing_source if the source does not exist" do
      result = instance.with_api_guard("ghost-slug") { :executed }
      expect(result).to eq(:missing_source)
    end

    it "yields the source object to the block" do
      yielded_source = nil
      instance.with_api_guard(slug) do |s|
        yielded_source = s
      end
      expect(yielded_source).to eq(source)
    end
  end

  describe "#can_fetch?" do
    before { JobBoards::Source.create!(slug: slug, name: "Test") }

    it "returns true if never fetched" do
      expect(instance.can_fetch?(slug)).to be true
    end

    it "returns false if within cooldown" do
      instance.with_api_guard(slug) { :executed }
      expect(instance.can_fetch?(slug)).to be false
    end

    it "returns true after cooldown expires" do
      instance.with_api_guard(slug, cooldown: 1.second) { :executed }
      sleep 1.1
      expect(instance.can_fetch?(slug, cooldown: 1.second)).to be true
    end
  end
end
