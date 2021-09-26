# frozen_string_literal: true

class CreateDomains < ActiveRecord::Migration[6.1]
  def change
    create_table :domains do |t|
      t.string :name

      t.timestamps
    end
  end
end
