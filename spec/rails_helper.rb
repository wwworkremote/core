# frozen_string_literal: true


require 'simplecov'
SimpleCov.start 'rails' do
  add_filter 'app/controllers/concerns/authenticatable.rb'
  add_group 'LLM Services', 'app/services/LLM'
  add_group 'Scrapers', 'app/services/scraper'
end

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

# STRICT GUARD: Never allow tests to touch the development database
abort("\nFATAL ERROR: Attempted to run tests against the development database. \nExecution halted to prevent data loss. \nCheck your RAILS_ENV or database.yml configuration.\n") if ActiveRecord::Base.connection_db_config.name == 'development' || ActiveRecord::Base.connection.current_database == 'wwworkremote_development'

require 'rspec/rails'

require 'webmock/rspec'
require 'capybara/cuprite'

# Add additional requires below this line. Rails is not loaded until this point!

Capybara.javascript_driver = :cuprite
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app,
                                window_size: [1200, 800],
                                browser_options: { 'no-sandbox': true },
                                process_timeout: 60,
                                timeout: 60,
                                pending_connection_errors: false,
                                inspector: true)
end

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }
Dir[File.join(__dir__, 'support/**/*.rb')].each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError
  exit 1
end
RSpec.configure do |config|
  config.example_status_persistence_file_path = 'tmp/rspec_failures.txt'
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.include FactoryBot::Syntax::Methods

  config.before do
    # Stub Geocoder
    Geocoder.configure(lookup: :test, ip_lookup: :test)
    Geocoder::Lookup::Test.add_stub(
      'Worldwide', [
        {
          'latitude' => 0.0,
          'longitude' => 0.0,
          'address' => 'Worldwide',
          'state' => 'Worldwide',
          'state_code' => 'WW',
          'country' => 'Worldwide',
          'country_code' => 'WW'
        }
      ]
    )
  end

  # Filter lines from Rails gems in backtraces.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
