# frozen_string_literal: true

class CreateSources < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL.squish
      create table public.sources (
        id uuid not null default gen_random_uuid(),
        "event" jsonb not null default '{}'::jsonb,
        payload jsonb not null default '{}'::jsonb,
        created_at timestamp(6) without time zone not null default CURRENT_TIMESTAMP,
        primary key (id, created_at)
      ) partition by range (created_at);
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
