# frozen_string_literal: true

class HelloWorker
  include Sidekiq::Worker

  def perform
    puts 'hello'
    Rails.logger.debug('Hello')
  end
end
