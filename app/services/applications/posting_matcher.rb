# frozen_string_literal: true

# Finds the JobPosting an imported application row refers to.
#
# Shared by the backfill importers because the same real application arrives
# from several places: a LinkedIn job-alert email, the LinkedIn tracker,
# my.greenhouse.io, and Indeed's appStatusJobs all describe the same job with
# different URLs and different ids. Matching only on our own signature counts
# it once per source and inflates every funnel number.
#
# Order matters -- cheapest and most certain first:
#   1. our own signature for this source
#   2. the source's native id inside target_url
#   3. the exact target_url
#   4. company + title, which is the only thing that crosses sources
class Applications::PostingMatcher
  # row keys: :signature, :native_id_fragment, :target_url, :company, :title
  def self.call(row)
    by_signature(row[:signature]) ||
      by_native_id(row[:native_id_fragment]) ||
      by_target_url(row[:target_url]) ||
      by_company_and_title(row[:company], row[:title])
  end

  def self.by_signature(signature)
    JobPosting.find_by(signature: signature)
  end

  def self.by_native_id(fragment)
    return nil if fragment.blank?

    JobPosting.where("target_url LIKE ?", "%#{fragment}%").first
  end

  def self.by_target_url(url)
    return nil if url.blank?

    JobPosting.find_by(target_url: url)
  end

  # Cross-source match. Deliberately requires both, and both non-blank: a great
  # many scraped rows arrive with company_name nil, and matching on title alone
  # would collapse every "Staff Software Engineer" into one row.
  #
  # ponytail: exact normalized match. TASK-78's overlap-coefficient matcher
  # would also catch "Files.com" vs "Files.com, Inc", but exact match has no
  # false-positive mode and covers the overlap actually observed. Upgrade when
  # a real miss shows up, not before.
  def self.by_company_and_title(company, title)
    company = normalize(company)
    title = normalize(title)
    return nil if company.blank? || title.blank?

    JobPosting.where("LOWER(TRIM(company_name)) = ? AND LOWER(TRIM(title)) = ?", company, title).first
  end

  def self.normalize(value)
    value.to_s.strip.downcase
  end

  private_class_method :by_signature, :by_native_id, :by_target_url, :by_company_and_title, :normalize
end
