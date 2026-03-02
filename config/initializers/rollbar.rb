# frozen_string_literal: true

if defined?(Rollbar)
  Rollbar.configure do |config|
    # Without configuration, Rollbar is enabled in all environments.
    # To disable in specific environments, set config.enabled=false.

    config.access_token = 'ae434ccc71be4714bfa46622f0d61b4f'

    # Here we'll disable in 'test':
    if Rails.env.test?
      config.enabled = false
    end

    # By default, Rollbar will try to call the `current_user` method in your controllers
    # to fetch logged-in user information, and then pull that user's ID, username,
    # and email. If your user model has different names for these attributes,
    # you can customize them with 'user_attributes'.
    # config.user_attributes = [:id, :username, :email]

    # Add exception class names to the `exception_level_filters` hash to
    # change the level that exception is reported at. Note that if an exception
    # has already been reported, it won't be reported again unless it is
    # within the time period specified by `failover_handlers`.
    # config.exception_level_filters.merge!('MyCustomException' => 'critical')
    #
    # You can also specify a callable, which will be called with the exception instance.
    # config.exception_level_filters.merge!('MyCustomException' => lambda { |e| 'critical' })

    # Enable asynchronous reporting (uses 'sucker_punch' gem)
    # config.use_sucker_punch

    # Enable asynchronous reporting (uses 'sidekiq' gem)
    # config.use_sidekiq
    # config.use_sidekiq = { 'queue' => 'default' }

    # If your model has a custom primary key other than 'id', you can specify it here:
    # config.person_method = "my_current_user"
    # config.person_id_method = "my_id"
    # config.person_username_method = "my_username"
    # config.person_email_method = "my_email"

    # If you want to use custom log levels for different environments, you can do so here:
    # config.environment = 'production'
  end
end
