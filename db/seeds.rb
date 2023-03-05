# frozen_string_literal: true

# source = JobBoards::Source.find_or_create_by(name: 'HackerNews', slug: 'hackernews')
# JobBoards::Query.find_or_create_by(source_id: source.id)

name = slug = ENV.fetch('ADMIN_NAME', 'admin')
email = ENV.fetch('ADMIN_EMAIL', 'admin@just3ws.com')
password = password_confirmation = ENV.fetch('ADMIN_PASSWORD', 'password')

admin = User
        .create_with(name:, email:, password:, password_confirmation:)
        .find_or_initialize_by(slug:)

admin.skip_confirmation!
admin.save!
