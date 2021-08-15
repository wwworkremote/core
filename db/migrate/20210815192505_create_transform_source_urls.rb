# frozen_string_literal: true

class CreateTransformSourceUrls < ActiveRecord::Migration[6.1]
  def change
    create_view :transform_source_urls
  end
end
