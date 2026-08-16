# frozen_string_literal: true

require "English"
namespace :quality do
  desc "Run all static analysis tools (RuboCop, Brakeman, Reek, Flay, Flog, RailsBestPractices, Bundle-Audit)"
  task all: :environment do
    errors = []
    # rake quality runs under RAILS_ENV=test in CI, immediately before `rspec`
    # against the same DB -- SystemInsight writes here are real, non-transactional,
    # and would leak into the shared test DB that specs depend on (TASK-35).
    ingest = !Rails.env.test?
    puts "\nℹ️  RAILS_ENV=test: skipping SystemInsight writes (see TASK-35)" unless ingest

    puts "\n🔍 Running RuboCop..."
    rubocop_report = `bundle exec rubocop -f json`
    if $CHILD_STATUS.success? || !rubocop_report.empty?
      Quality::InsightIngester.ingest_rubocop(rubocop_report) if ingest
      puts "✅ RuboCop findings#{ingest ? ' ingested' : ' collected'}."
    else
      errors << "RuboCop failed to run"
    end

    puts "\n🛡️ Running Brakeman..."
    brakeman_report = `bundle exec brakeman -q -w2 --no-pager -f json`
    if $CHILD_STATUS.success? || !brakeman_report.empty?
      Quality::InsightIngester.ingest_brakeman(brakeman_report) if ingest
      puts "✅ Brakeman findings#{ingest ? ' ingested' : ' collected'}."
    else
      errors << "Brakeman failed to run"
    end

    puts "\n👃 Running Reek..."
    reek_report = `bundle exec reek -f json`
    if $CHILD_STATUS.success? || !reek_report.empty?
      Quality::InsightIngester.ingest_reek(reek_report) if ingest
      puts "✅ Reek findings#{ingest ? ' ingested' : ' collected'}."
    else
      errors << "Reek failed to run"
    end

    puts "\n👯 Running Flay..."
    errors << "Flay failed" unless system("bundle exec flay app/")

    puts "\n🐸 Running Flog..."
    errors << "Flog failed" unless system("bundle exec flog app/")

    puts "\n🛤️ Running Rails Best Practices..."
    errors << "Rails Best Practices failed" unless system("bundle exec rails_best_practices .")

    puts "\n🗺️ Running Traceroute..."
    errors << "Traceroute failed" unless system("bundle exec rake traceroute")

    puts "\n💀 Running Debride..."
    errors << "Debride failed" unless system("bundle exec debride app/")

    puts "\n📐 Running Database Consistency..."
    errors << "Database Consistency failed" unless system("bundle exec database_consistency")

    puts "\n📦 Running Packwerk..."
    errors << "Packwerk failed" unless system("bundle exec packwerk check")

    puts "\n📦 Running Bundle-Audit..."
    errors << "Bundle-Audit failed" unless system("bundle exec bundle-audit check --update")

    if errors.any?
      puts "\n❌ Quality checks failed:"
      errors.each { |e| puts "  - #{e}" }
      exit 1
    else
      puts "\n✅ All quality checks passed!"
    end
  end
end

desc "Shortcut for quality:all"
task quality: "quality:all"
