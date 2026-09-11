# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks

require "socket"

desc "Create User"
task create_user: :environment do
  User
    .create_with(name: "Mike Hall", email: "mike@just3ws.com")
    .find_or_create_by(slug: "mike.hall")
end
