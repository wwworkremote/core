# frozen_string_literal: true

class EnablePgvector < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'vector'
    enable_extension 'pg_trgm' # For advanced text search
  end
end
