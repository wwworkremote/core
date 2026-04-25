# frozen_string_literal: true

class EmailImportJob < ApplicationJob
  queue_as :light
  mediumweight!
  idempotent! ->(source) { "email_import/#{source}" }

  def perform(source)
    EmailImporter.new.call(source: source)
  end
end
