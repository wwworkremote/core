# frozen_string_literal: true

require "pagy"

# Pagy 43.5.1 Compatibility Layer for gems expecting Pagy 9.x/Older
# Pagy 43+ changed its internal structure significantly.
class Pagy
  # ahoy_captain and others expect Pagy::Frontend
  Frontend = NumericHelpers unless defined?(Frontend)

  # ahoy_captain expects Pagy::Backend
  # In Pagy 43, Method is the module defining the #pagy method
  Backend = Method unless defined?(Backend)
end
