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

  BUILDERS = {
    "cord" => :build_cord_url,
    "linkedin" => :build_linkedin_url,
    "indeed" => :build_indeed_url,
    "dice" => :build_dice_url,
    "remoteok" => :build_remoteok_url
  }.freeze

  def build_url
    builder = BUILDERS[board_name.to_s.downcase]
    builder ? send(builder) : nil
  end

  def build_cord_url
    query = { filters: cord_filters.to_json, v: { label: "Positions", value: "listing" }.to_json,
              resultType: "all" }
    "https://cord.com/search/jobs/#{terms.first.parameterize}?#{query.to_query}"
  end

  def cord_filters
    base_filters + cord_remote_filters + cord_seniority_filters + cord_salary_filters
  end

  def base_filters
    [{ a: "sortBy", l: "Responsiveness", v: "response_rate" }, { a: "keyword", l: terms.first, v: terms.first }]
  end

  def cord_remote_filters
    return [] unless query_params["remote"]

    [{ a: "remote", l: " Remote", v: "remote" }] + cord_country_filter
  end

  def cord_country_filter
    return [] if query_params["country"].blank?

    [{ a: "remoteLocationCountries", l: " #{query_params['country']}", v: query_params["country"] }]
  end

  def cord_seniority_filters
    Array(query_params["seniority"]).map { |s| { a: "seniority", l: " #{s.capitalize}", v: s.downcase } }
  end

  def cord_salary_filters
    return [] if query_params["min_salary"].blank?

    [{ a: "salary", l: "Min: £#{formatted_salary}", v: query_params["min_salary"].to_i }]
  end

  def formatted_salary
    query_params["min_salary"].to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\1,')
  end

  def build_linkedin_url
    keyword = terms.first
    query = { keywords: keyword, location: query_params["location"] || "United States" }
    query[:f_WT] = 2 if query_params["remote"]
    "https://www.linkedin.com/jobs/search/?#{query.to_query}"
  end

  def build_indeed_url
    keyword = terms.first
    query = { q: keyword, l: query_params["location"] || "Remote" }
    # Remote attribute for Indeed
    query[:sc] = "0kf:attr(DSQF7);" if query_params["remote"]
    "https://www.indeed.com/jobs?#{query.to_query}"
  end

  def build_dice_url
    keyword = terms.first
    query = { q: keyword, countryCode: "US", radius: 30, radiusUnit: "mi", page: 1, pageSize: 20 }
    query["filters.isRemote"] = "true" if query_params["remote"]
    "https://www.dice.com/jobs?#{query.to_query}"
  end

  def build_remoteok_url
    keyword = terms.first
    "https://remoteok.com/remote-#{keyword.parameterize}-jobs"
  end
end
