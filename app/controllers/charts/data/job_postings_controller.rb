# frozen_string_literal: true

module Charts
  module Data
    class JobPostingsController < DataController
      def index
        Rails.logger.info "DEBUG: Reached JobPostingsController#index with params: #{params.inspect}"
        @days = Integer(params['days'] || 1)
        @days = 1 unless @days.positive?

        render json: JobPosting.where(published_at: @days.days.ago..).group_by_day(:published_at).count
      end

      def corpus
        job_postings = JobPosting.where(published_at: Time.zone.now.all_month).order(id: :desc).limit(1_000).pluck(:title, :body)

        @corpus = job_postings.each_with_object({ names: [], descriptions: [] }) do |jp, c|
          c[:names] << jp.first.to_s.gsub(/\s\+/, ' ').downcase.strip
          c[:descriptions] << jp.last.to_s.gsub(/\s\+/, ' ').downcase.strip
        end

        render json: @corpus.as_json
      end
    end
  end
end
