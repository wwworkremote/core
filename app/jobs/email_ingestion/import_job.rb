# frozen_string_literal: true

module EmailIngestion
  class ImportJob < ApplicationJob
    queue_as :default
    mediumweight!
    idempotent! ->(source) { "email_import/#{source}" }

    def perform(source)
      EmailIngestion::Importer.new.call(source: source)
    end
  end
end
