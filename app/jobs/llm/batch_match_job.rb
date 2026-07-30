# frozen_string_literal: true

class LLM::BatchMatchJob < ApplicationJob
  queue_as :heavy
  heavyweight!
  idempotent!

  def perform(limit: 50)
    return if SystemSetting.paused?

    admin_user = find_admin_user
    return if admin_user.career_profile&.resume_text.blank?

    match_target_postings(admin_user, limit)
  end

  private

  def find_admin_user
    User.find_by!(email: ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com"))
  end

  # Target: High-priority roles not yet analyzed, prioritized by newest arrival
  def target_postings(admin_user, limit)
    JobPosting.where("title ILIKE ANY (ARRAY[?])", ["%ruby%", "%rails%", "%staff%", "%principal%"])
              .where.not(id: UserJobPosting.where(user: admin_user).select(:job_posting_id))
              .order(created_at: :desc)
              .limit(limit)
  end

  def match_target_postings(admin_user, limit)
    target_postings(admin_user, limit).each do |job|
      check_cancellation!
      LLM::ProfileMatcher.call(admin_user, job)
    end
  end
end
