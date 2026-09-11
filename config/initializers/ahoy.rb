# frozen_string_literal: true

class Ahoy::Store < Ahoy::DatabaseStore
end

# set to true for JavaScript tracking
Ahoy.api = true

# ahoy_matey's own engine only registers vendor/assets/javascripts with
# Sprockets, not Propshaft (this app's asset pipeline), so ahoy.js
# (https://github.com/ankane/ahoy.js, vendored by the gem) needs its path
# added manually for `pin "ahoy", to: "ahoy.js"` in importmap.rb to resolve.
Rails.application.config.assets.paths << Ahoy::Engine.root.join("vendor/assets/javascripts")

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false
