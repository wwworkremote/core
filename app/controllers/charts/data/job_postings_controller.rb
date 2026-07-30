# frozen_string_literal: true

class Charts::Data::JobPostingsController < DataController
  def index
    render json: velocity_data
  end

  def corpus
    render json: corpus_data.as_json
  end

  private

  def days
    @days ||= Integer(params["days"] || 1)
    @days = 1 unless @days.positive?
    @days
  end

  # Use created_at for velocity monitoring since published_at can be missing or stale
  def velocity_data
    days == 1 ? hourly_velocity : daily_velocity
  end

  def hourly_velocity
    JobPosting.where(created_at: 24.hours.ago..).group_by_hour(:created_at).count
  end

  def daily_velocity
    JobPosting.where(created_at: days.days.ago..).group_by_day(:created_at).count
  end

  def corpus_data
    corpus_job_postings.each_with_object({ names: [], descriptions: [] }) do |row, corpus|
      append_corpus_row(corpus, row)
    end
  end

  def append_corpus_row(corpus, row)
    title, body = row
    corpus[:names] << normalize_corpus_text(title)
    corpus[:descriptions] << normalize_corpus_text(body)
  end

  def corpus_job_postings
    JobPosting.where(published_at: Time.zone.now.all_month).order(id: :desc).limit(1_000).pluck(:title, :body)
  end

  def normalize_corpus_text(text)
    text.to_s.gsub(/\s\+/, " ").downcase.strip
  end
end
