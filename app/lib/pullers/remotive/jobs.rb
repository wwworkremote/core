# frozen_string_literal: true

module Pullers
  module Remotive
    class Jobs
      attr_reader :client, :params, :path

      def initialize(client: nil, params: nil, path: nil, term: nil)
        @client = client || Remotive.client
        @params = (params || {
          limit: nil,
          category: 'software-dev',
          company_name: nil,
          search: term.presence || 'ruby'
        }).compact_blank

        @path = path.to_s.strip
      end

      def call
        request
        self
      end

      def request
        @request ||= client.get(path, params)
      end

      def data
        @data ||= request.body
      end
    end
  end
end

# # Remotive API
#
# ## category
#
# Retrieve jobs only for this category. Category name or category slug must be
# provided here. Existing categories are available at this endoint.
#
# ```
# https://remotive.io/api/remote-jobs?category=software-dev
# ```
#
# ## company_name
#
# Filter by company name. Case insensitive, partial match ('ilike') will be used
# here to filter job listings based on provided company name.
#
# ```
# https://remotive.io/api/remote-jobs?company_name=remotive
# ```
#
# ## search
#
# Search job listing title and description. Case insensitive, partial match
# ('ilike') will be used here to filter job listings.
#
# ```
# https://remotive.io/api/remote-jobs?search=front%20end
# ```
#
# ## limit
#
# Limit the number of job listing results (default: all). An integer must be
# provided.
#
# ```
# https://remotive.io/api/remote-jobs?limit=5
# ```
