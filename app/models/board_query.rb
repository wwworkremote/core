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
  serialize :query_params, type: Hash, coder: JSON

  def build_cord_url
    return nil unless board_name == 'cord'
    
    # Base URL component from terms
    keyword = terms.first
    base_slug = keyword.parameterize
    
    # Build dynamic filter array
    filters = [
      { a: 'sortBy', l: 'Responsiveness', v: 'response_rate' },
      { a: 'keyword', l: keyword, v: keyword }
    ]
    
    # Handle remote/location
    if query_params['remote']
      filters << { a: 'remote', l: ' Remote', v: 'remote' }
      if query_params['country'].present?
        filters << { a: 'remoteLocationCountries', l: " #{query_params['country']}", v: query_params['country'] }
      end
    end

    # Handle seniority (expecting array)
    Array(query_params['seniority']).each do |s|
      filters << { a: 'seniority', l: " #{s.capitalize}", v: s.downcase }
    end

    # Handle salary (min)
    if query_params['min_salary'].present?
      filters << { a: 'salary', l: "Min: £#{query_params['min_salary'].to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\1,')}", v: query_params['min_salary'].to_i }
    end
    
    # Construct query
    query = {
      filters: filters.to_json,
      v: { label: 'Positions', value: 'listing' }.to_json,
      resultType: 'all'
    }
    
    "https://cord.com/search/jobs/#{base_slug}?#{query.to_query}"
  end
end
