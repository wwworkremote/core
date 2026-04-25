# frozen_string_literal: true

class Charts::Data::JobPostingsController < DataController
  def index
    @days = Integer(params['days'] || 1)
    @days = 1 unless @days.positive?

    # Use created_at for velocity monitoring since published_at can be missing or stale
    if @days == 1
      render json: JobPosting.where(created_at: 24.hours.ago..).group_by_hour(:created_at).count
    else
      render json: JobPosting.where(created_at: @days.days.ago..).group_by_day(:created_at).count
    end
  end

  def corpus
    job_postings = JobPosting.where(published_at: Time.zone.now.all_month).order(id: :desc).limit(1_000).pluck(
      :title, :body
    )

    @corpus = job_postings.each_with_object({ names: [], descriptions: [] }) do |jp, c|
      c[:names] << jp.first.to_s.gsub(/\s\+/, ' ').downcase.strip
      c[:descriptions] << jp.last.to_s.gsub(/\s\+/, ' ').downcase.strip
    end

    render json: @corpus.as_json
  end
end
