# frozen_string_literal: true

# == Schema Information
#
# Table name: board_queries
#
#  id           :bigint           not null, primary key
#  board_name   :string
#  priority     :integer
#  query_params :json
#  remote       :boolean
#  terms        :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class BoardQuery < ApplicationRecord
  serialize :terms, type: Array, coder: JSON

  def build_url
    case board_name.to_s.downcase
    when 'cord' then build_cord_url
    when 'linkedin' then build_linkedin_url
    when 'indeed' then build_indeed_url
    when 'dice' then build_dice_url
    when 'remoteok' then build_remoteok_url
    end
  end

  def build_cord_url
    # ... existing cord logic ...
    keyword = terms.first
    base_slug = keyword.parameterize

    filters = [
      { a: 'sortBy', l: 'Responsiveness', v: 'response_rate' },
      { a: 'keyword', l: keyword, v: keyword }
    ]

    if query_params['remote']
      filters << { a: 'remote', l: ' Remote', v: 'remote' }
      filters << { a: 'remoteLocationCountries', l: " #{query_params['country']}", v: query_params['country'] } if query_params['country'].present?
    end

    Array(query_params['seniority']).each { |s| filters << { a: 'seniority', l: " #{s.capitalize}", v: s.downcase } }
    filters << { a: 'salary', l: "Min: £#{query_params['min_salary'].to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\1,')}", v: query_params['min_salary'].to_i } if query_params['min_salary'].present?

    query = { filters: filters.to_json, v: { label: 'Positions', value: 'listing' }.to_json, resultType: 'all' }
    "https://cord.com/search/jobs/#{base_slug}?#{query.to_query}"
  end

  def build_linkedin_url
    keyword = terms.first
    query = { keywords: keyword, location: query_params['location'] || 'United States' }
    query[:f_WT] = 2 if query_params['remote']
    "https://www.linkedin.com/jobs/search/?#{query.to_query}"
  end

  def build_indeed_url
    keyword = terms.first
    query = { q: keyword, l: query_params['location'] || 'Remote' }
    # Remote attribute for Indeed
    query[:sc] = '0kf:attr(DSQF7);' if query_params['remote']
    "https://www.indeed.com/jobs?#{query.to_query}"
  end

  def build_dice_url
    keyword = terms.first
    query = { q: keyword, countryCode: 'US', radius: 30, radiusUnit: 'mi', page: 1, pageSize: 20 }
    query['filters.isRemote'] = 'true' if query_params['remote']
    "https://www.dice.com/jobs?#{query.to_query}"
  end

  def build_remoteok_url
    keyword = terms.first
    "https://remoteok.com/remote-#{keyword.parameterize}-jobs"
  end
end
