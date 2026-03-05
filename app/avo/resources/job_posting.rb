# frozen_string_literal: true

class Avo::Resources::JobPosting < Avo::BaseResource
  self.title = :title
  self.includes = [:source]
  self.search = {
    query: -> { query.ransack(title_cont: params[:q], company_cont: params[:q], m: 'or').result(distinct: false) }
  }

  def filters
    filter Avo::Filters::SourceFilter
  end

  def fields
    field :id, as: :id
    field :title, as: :text, link_to_record: true
    field :company, as: :text
    field :location, as: :text
    field :published_at, as: :date_time
    field :target_url, as: :text
    field :latitude, as: :number
    field :longitude, as: :number
    field :source, as: :belongs_to
  end
end
