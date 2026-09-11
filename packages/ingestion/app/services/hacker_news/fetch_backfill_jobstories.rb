# frozen_string_literal: true

class HackerNews::FetchBackfillJobstories
  attr_reader :offset, :limit

  def initialize(offset: 1, limit: 200)
    @offset = offset
    @limit = limit
  end

  def call
    maxitemid = HackerNews::V0::Jobstory.minimum(:id)
    minitemid = maxitemid - limit

    jobstory_ids = (minitemid..maxitemid).to_a

    ap jobstory_ids.minmax

    HackerNews::FetchJobstories.new(jobstory_ids:).call
  end
end
