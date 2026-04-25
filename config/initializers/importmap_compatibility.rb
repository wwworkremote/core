# frozen_string_literal: true

# Compatibility layer for importmap-rails 2.x
# ahoy_captain 1.2.0 expects shim tags that were removed in importmap-rails 2.0
ActiveSupport.on_load(:action_view) do
  def javascript_importmap_shim_tag
    nil
  end

  def javascript_importmap_shim_nonce_configuration_tag
    nil
  end
end
