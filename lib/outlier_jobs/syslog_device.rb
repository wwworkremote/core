# frozen_string_literal: true

require 'syslog'
# require 'syslog/logger'

module OutlierJobs
  class SyslogDevice
    extend Forwardable

    LEVEL_MAP = {
      ::Logger::UNKNOWN => Syslog::LOG_ALERT,
      ::Logger::FATAL => Syslog::LOG_ERR,
      ::Logger::ERROR => Syslog::LOG_WARNING,
      ::Logger::WARN => Syslog::LOG_NOTICE,
      ::Logger::INFO => Syslog::LOG_INFO,
      ::Logger::DEBUG => Syslog::LOG_DEBUG
    }.freeze

    def syslog_level
      LEVEL_MAP[Rails.logger&.level || ::Logger::DEBUG]
    end

    def initialize(prog_name)
      @log = Syslog.open(prog_name)
      apply_syslog_mask
    end

    def write(message)
      apply_syslog_mask
      @log.log(syslog_level, message)
    end

    def apply_syslog_mask
      Syslog.mask = Syslog::LOG_UPTO(syslog_level) if Syslog.mask != Syslog::LOG_UPTO(syslog_level)
    end

    def_delegator :@log, :close
  end
end
