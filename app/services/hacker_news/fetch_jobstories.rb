# frozen_string_literal: true

require 'hacker_news'

module HackerNews
  class FetchJobstories
    attr_reader :jobstory_ids

    def initialize(jobstory_ids:)
      @jobstory_ids = jobstory_ids
    end

    def call
      jobstory_ids.each do |jobstory_id|
        Rails.logger.info { "#{self.class.name}##{__method__} ==>> jobstory_id:#{jobstory_id}" }
        HackerNews::FetchJobstoryWorker.new.perform(jobstory_id)
      end
    end
  end
end
