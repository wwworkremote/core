# frozen_string_literal: true

# Shared base for the sandbox provider (docs/architecture/sandbox-provider.md).
# No app chrome -- these pages stand alone as a fake ATS, not part of the
# WWWorkRemote admin UI. The route these controllers are mounted under
# doesn't exist at all outside development/test (config/routes.rb), so
# there's no separate auth story to build here.
class Sandbox::ApplicationController < ApplicationController
  layout false
end
