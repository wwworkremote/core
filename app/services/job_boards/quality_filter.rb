# frozen_string_literal: true

module JobBoards
  class QualityFilter
    BANNED_TITLES = [
      '/JOB_POSTINGS',
      '/JOBS',
      'Sign In',
      'Log In',
      'Navigation',
      'Menu',
      'Job Search'
    ].freeze

    def initialize(job_posting)
      @job_posting = job_posting
    end

    def useful?
      return false if @job_posting.title.blank?
      return false if BANNED_TITLES.any? { |banned| @job_posting.title.upcase == banned.upcase }
      return false if @job_posting.title.length < 3
      
      # If body is extremely short and it's from a known "noisy" source, it might be junk
      return false if @job_posting.body.blank? || @job_posting.body.length < 50
      
      true
    end
  end
end
