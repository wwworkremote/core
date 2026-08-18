# frozen_string_literal: true

# PaperTrail's `changeset`/`object_changes` are permanently nil without this
# column (see PaperTrail::VersionConcern#changeset -- it returns nil unless
# the column exists, it does not derive a diff from `object` after the
# fact). Versions recorded before this migration won't have object_changes
# retroactively; new ones will, automatically, once the column exists.
class AddObjectChangesToVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :versions, :object_changes, :text
  end
end
