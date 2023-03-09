# frozen_string_literal: true

require 'hacker_news'

module HackerNews
  class FetchJobstories
    attr_reader :jobstory_ids

    def initialize(jobstory_ids:)
      @jobstory_ids = jobstory_ids
    end

    def call
      jobstory_ids.each_with_index do |jobstory_id, i|
        Rails.logger.info { "#{self.class.name}##{__method__} ==>> jobstory_id:#{jobstory_id}" }
        HackerNews::FetchJobstoryWorker.set(wait_until: i.minutes).perform_async(jobstory_id)
      end
    end
  end
end
