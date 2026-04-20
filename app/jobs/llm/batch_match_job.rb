class Llm::BatchMatchJob < ApplicationJob
  queue_as :default

  def perform(limit: 50)
    admin_user = User.find_by!(email: ENV.fetch('ADMIN_EMAIL', 'mike@just3ws.com'))
    return unless admin_user.career_profile&.resume_text.present?

    # Target: High-priority roles not yet analyzed, prioritized by newest arrival
    targets = JobPosting.where("title ILIKE ANY (ARRAY[?])", ['%ruby%', '%rails%', '%staff%', '%principal%'])
                        .where.not(id: UserJobPosting.where(user: admin_user).select(:job_posting_id))
                        .order(created_at: :desc)
                        .limit(limit)

    targets.each do |job|
      Llm::ProfileMatcher.call(admin_user, job)
    end
  end
end
