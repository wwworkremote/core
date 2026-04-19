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
    
    # Build filter array
    filters = [
      { a: 'sortBy', l: 'Responsiveness', v: 'response_rate' },
      { a: 'keyword', l: keyword, v: keyword }
    ]
    
    # Construct query
    query = {
      filters: filters.to_json,
      v: { label: 'Positions', value: 'listing' }.to_json,
      resultType: 'all'
    }
    
    "https://cord.com/search/jobs/#{base_slug}?#{query.to_query}"
  end
end
