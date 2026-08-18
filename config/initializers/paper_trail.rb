# frozen_string_literal: true

# versions.object/object_changes are YAML (PaperTrail's default serializer),
# and Rails' safe YAML loader rejects any class not on this allowlist --
# without it, PaperTrail::Version#changeset/object silently return nil for
# any version whose attributes include a Time/TimeWithZone (i.e. every
# version, since created_at/updated_at are always present).
ActiveRecord.yaml_column_permitted_classes += [
  Time,
  Date,
  DateTime,
  ActiveSupport::TimeWithZone,
  ActiveSupport::TimeZone,
  BigDecimal
]
