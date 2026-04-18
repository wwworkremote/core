# frozen_string_literal: true

module Avo
  module Resources
    class JobPosting < Avo::BaseResource
      self.title = :title
      self.includes = [:source]
      self.search = {
        query: -> { query.ransack(title_cont: params[:q], company_cont: params[:q], m: 'or').result(distinct: false) }
      }

      def filters
        filter Avo::Filters::SourceFilter
        filter Avo::Filters::AiCategoryFilter
      end

      def fields
        field :title, as: :text, link_to_record: true
        field :company, as: :text
        field :location, as: :text

        field :ai_category, as: :badge, options: {
          success: 'Product Management',
          warning: 'Design',
          error: 'Sales',
          info: 'Software Engineering',
          neutral: 'Other'
        } do |record|
          record&.data&.[]('ai_category')
        end

        field :found_by_terms, as: :tags, hide_on: :index do |record|
          record&.data&.[]('found_by_terms')
        end

        field :published_at, as: :date_time, name: 'Posted'
        field :target_url, as: :text, hide_on: :index
        field :source, as: :belongs_to

        tool Avo::ResourceTools::SimilarJobs
      end
    end
  end
end
