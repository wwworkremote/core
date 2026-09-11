# frozen_string_literal: true

class Charts::Data::PipelineController < ApplicationController
  def health
    # Total documents per source in the last 7 days
    data = JobBoards::Document.joins(:job_boards_source)
                              .where(created_at: 7.days.ago..)
                              .group("job_boards_sources.name")
                              .count
    render json: data
  end

  def funnel
    render json: processing_funnel_counts.to_a
  end

  private

  # Processing distribution -- one cohesive hash literal, splitting it
  # further would obscure it, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def processing_funnel_counts
    {
      "Raw Documents" => JobBoards::Document.count,
      "Job Postings" => JobPosting.count,
      "AI Classified" => JobPosting.where("data->>'ai_category' IS NOT NULL").count,
      "Vector Indexed" => JobPosting.where.not(embedding: nil).count
    }
  end
  # rubocop:enable Metrics/MethodLength
end
