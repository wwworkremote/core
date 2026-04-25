# frozen_string_literal: true

class EmailIngestion::ImportJob < ApplicationJob
  queue_as :light
  mediumweight!
  idempotent! ->(source) { "email_import/#{source}" }

  def perform(source)
    EmailIngestion::Importer.new.call(source: source)
  end
end
