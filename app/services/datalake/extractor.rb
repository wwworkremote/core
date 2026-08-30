# frozen_string_literal: true

# ADR 010 / TASK-123 read contract: base class for anything that derives
# operational data from a guided session's raw datalake bundle (DOM, HAR,
# screenshots). One subclass per consumer -- e.g. the question graph's DOM
# occurrence extractor.
#
# The contract each subclass keeps:
#   - declare a `version`; bump it only when identical raw material would yield
#     materially different output (same discipline as
#     Scenarios::ComparisonRules::VERSION).
#   - read raw bytes only through the Bundle passed in, never File.read.
#   - persist results into your *own* domain tables, each row stamped with the
#     extractor version. On read, `stale?(row.datalake_extractor_version)`
#     decides whether to re-extract.
#
# Cadence (per the contract): cheap value-free derivation stays inline on
# GuidedSession#complete!. A subclass here is for the expensive work --
# enqueued on the first read that needs it, with a "still extracting" state on
# the view until the job lands.
class Datalake::Extractor
  class << self
    def key = name.demodulize.underscore

    def version = raise NotImplementedError, "#{name} must declare a version"

    def call(bundle) = new(bundle).extract

    def stale?(stamped_version) = stamped_version.to_s != version.to_s
  end

  def initialize(bundle)
    @bundle = bundle
  end

  attr_reader :bundle

  def extract = raise NotImplementedError, "#{self.class.name} must implement #extract"

  delegate :version, to: :class
end
