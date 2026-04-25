# frozen_string_literal: true

namespace :quality do
  desc 'Run all static analysis tools (RuboCop, Brakeman, Reek, Flay, RailsBestPractices, Bundle-Audit)'
  task all: :environment do
    errors = []

    puts "\n🔍 Running RuboCop..."
    rubocop_report = `bundle exec rubocop -f json`
    if $?.success? || !rubocop_report.empty?
      Quality::InsightIngester.ingest_rubocop(rubocop_report)
      puts "✅ RuboCop findings ingested."
    else
      errors << 'RuboCop failed to run'
    end

    puts "\n🛡️ Running Brakeman..."
    brakeman_report = `bundle exec brakeman -q -w2 --no-pager -f json`
    if $?.success? || !brakeman_report.empty?
      Quality::InsightIngester.ingest_brakeman(brakeman_report)
      puts "✅ Brakeman findings ingested."
    else
      errors << 'Brakeman failed to run'
    end

    puts "\n👃 Running Reek..."
    reek_report = `bundle exec reek -f json`
    if $?.success? || !reek_report.empty?
      Quality::InsightIngester.ingest_reek(reek_report)
      puts "✅ Reek findings ingested."
    else
      errors << 'Reek failed to run'
    end

    puts "\n👯 Running Flay..."
    unless system('bundle exec flay app/')
      errors << 'Flay failed'
    end

    puts "\n🛤️ Running Rails Best Practices..."
    unless system('bundle exec rails_best_practices .')
      errors << 'Rails Best Practices failed'
    end

    puts "\n📦 Running Bundle-Audit..."
    unless system('bundle exec bundle-audit check --update')
      errors << 'Bundle-Audit failed'
    end

    if errors.any?
      puts "\n❌ Quality checks failed:"
      errors.each { |e| puts "  - #{e}" }
      exit 1
    else
      puts "\n✅ All quality checks passed!"
    end
  end
end

desc 'Shortcut for quality:all'
task quality: 'quality:all'
