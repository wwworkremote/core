# frozen_string_literal: true

# in a Rails initializer
PgParty.configure do |c|
  c.caching_ttl = 60
  c.schema_exclude_partitions = false
  c.include_subpartitions_in_partition_list = true
  # Postgres 11+ users starting fresh may consider the below options to rely on Postgres' native features instead of
  # this gem's template tables feature.
  c.create_template_tables = false
  c.create_with_primary_key = true
end
