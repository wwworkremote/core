# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

require 'socket'

desc 'Hello'
task hello: :environment do
  puts "hello: #{Socket.gethostname}"
end

desc 'Create User'
task create_user: :environment do
  User
    .create_with(name: 'Mike Hall', email: 'mike@just3ws.com')
    .find_or_create_by(slug: 'mike.hall')
end

# When running `rake assets:precompile` this is the order of events:
# 1 - Task `avo:yarn_install`
# 2 - Task `avo:sym_link`
# 3 - Cmd  `yarn avo:tailwindcss`
# 4 - Task `assets:precompile`
Rake::Task["assets:precompile"].enhance(["avo:sym_link"])
Rake::Task["avo:sym_link"].enhance(["avo:yarn_install"])
Rake::Task["avo:sym_link"].enhance do
  `yarn avo:tailwindcss`
end

