# frozen_string_literal: true

class Init < ActiveRecord::Migration[6.1]
  def up
    enable_extension 'citext'
    enable_extension 'hstore'
    enable_extension 'ltree'
    enable_extension 'pg_stat_statements'
    enable_extension 'pg_trgm'
    enable_extension 'pgcrypto'
    enable_extension 'plpgsql'
    enable_extension 'sslinfo'
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'The initial migration is not revertable'
  end
end
