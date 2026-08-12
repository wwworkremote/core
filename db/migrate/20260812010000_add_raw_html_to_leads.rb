# frozen_string_literal: true

class AddRawHtmlToLeads < ActiveRecord::Migration[8.1]
  def change
    add_column :leads, :raw_html, :text
  end
end
