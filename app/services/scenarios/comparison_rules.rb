# frozen_string_literal: true

# Version stamped onto every ReferenceComparison run (ADR 009). Bump ONLY when
# identical evidence could produce materially different findings or coverage --
# never for formatting, presentation, or performance-only changes. The upgrade
# path, if rules ever need to change without a deploy or vary per provider, is a
# row-backed registry (ADR 009 "Consequences").
module Scenarios::ComparisonRules
  VERSION = "1"
end
