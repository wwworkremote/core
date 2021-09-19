# frozen_string_literal: true

module OutlierJobs
  class Logger < Ougai::Logger
    include ActiveSupport::LoggerThreadSafeLevel
    include ActiveSupport::LoggerSilence if defined?(ActiveSupport::LoggerSilence)

    def initialize(*args)
      super
      after_initialize if respond_to? :after_initialize
    end

    def create_formatter
      return Ougai::Formatters::Pino.new if Rails.env.production?

      Ougai::Formatters::Readable.new
    end
  end
end
