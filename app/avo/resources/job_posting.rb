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
        field :id, as: :id
        field :title, as: :text, link_to_record: true
        field :company, as: :text
        field :location, as: :text
        field :ai_category, as: :text do |model|
          model.data['ai_category']
        end
        field :found_by_terms, as: :tags do |model|
          model.data['found_by_terms']
        end
        field :published_at, as: :date_time
        field :target_url, as: :text
        field :source, as: :belongs_to
      end
    end
  end
end
