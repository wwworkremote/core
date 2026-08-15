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

# Direct-hiring-page sources: companies picked for fit with this account's
# actual target roles (Rails-heavy engineering culture, regulated/complex
# domains -- fintech, healthtech, insurance -- Staff/Principal-level hiring),
# each slug/board live-verified against the provider's real public API
# before being added here. Extend these arrays (or add a new source below)
# to track more companies -- no code change needed, see each Fetcher class.
# Cengage was found by mining this DB's own already-ingested JobPosting rows
# for myworkdayjobs.com target_urls from prior sessions' work, not guessed --
# worth re-running that mining pass periodically as more postings land.
puts "== Seeding Direct-Hiring-Page Sources =="
[
  { name: "Greenhouse", slug: "greenhouse", boards: %w[doximity gusto toast] },
  { name: "Lever", slug: "lever", boards: %w[ro plaid palantir] },
  { name: "ADP (Direct)", slug: "adp", boards: %w[corpfollettexternal] },
  { name: "Workday", slug: "workday",
    boards: [
      { "tenant" => "myhrhome", "wd" => "wd1", "site" => "OneMainCareers" },
      { "tenant" => "cengage", "wd" => "wd5", "site" => "CengageNorthAmericaCareers" }
    ] }
].each do |source_attrs|
  source = JobBoards::Source.find_or_create_by!(slug: source_attrs[:slug]) { |s| s.name = source_attrs[:name] }
  query = JobBoards::Query.find_or_create_by!(source_id: source.id)
  query.update!(data: query.data.merge("boards" => source_attrs[:boards]))

  puts " - #{source_attrs[:name]} (slug: #{source_attrs[:slug]}, boards: #{source_attrs[:boards]})"
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

admin.save!
puts " - Admin: #{email} / #{password}"
