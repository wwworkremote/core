# frozen_string_literal: true

class EnableExtensions < ActiveRecord::Migration[7.0]
  def up
    enable_extension 'citext'
    enable_extension 'hstore'
    enable_extension 'ltree'
    enable_extension 'pg_stat_statements'
    enable_extension 'pg_trgm'
    enable_extension 'pgcrypto'
    enable_extension 'plpgsql'
    enable_extension 'sslinfo'
    enable_extension 'fuzzystrmatch'
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'The initial migration is not revertable'
  end
end
