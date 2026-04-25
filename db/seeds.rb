# frozen_string_literal: true

puts "== Seeding Data Sources =="
[
  { name: "Adzuna", slug: "adzuna" },
  { name: "Arbeitnow", slug: "arbeitnow" },
  { name: "HackerNews", slug: "hackernews" },
  { name: "Remotive", slug: "remotive" },
  { name: "Wwr", slug: "wwr" }
].each do |source_attrs|
  source = JobBoards::Source.find_or_create_by!(slug: source_attrs[:slug]) do |s|
    s.name = source_attrs[:name]
  end

  JobBoards::Query.find_or_create_by!(source_id: source.id)

  puts " - #{source_attrs[:name]} (slug: #{source_attrs[:slug]})"
end

puts "== Seeding LLM Models =="
LLM::Registry.sync
puts " - Models synced from config/models.yml"

puts "== Seeding Admin User =="
name = slug = ENV.fetch("ADMIN_NAME", "admin")
email = ENV.fetch("ADMIN_EMAIL", "admin@just3ws.com")
password = password_confirmation = ENV.fetch("ADMIN_PASSWORD", "password")

admin = User
        .create_with(name:, email:, password:, password_confirmation:)
        .find_or_initialize_by(slug:)

admin.skip_confirmation!
admin.save!
puts " - Admin: #{email} / #{password}"
