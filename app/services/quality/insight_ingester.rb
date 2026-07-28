# frozen_string_literal: true

class Quality::InsightIngester
  def self.ingest_brakeman(json_report)
    warnings = JSON.parse(json_report)["warnings"]
    deactivate(:brakeman, warnings.pluck("file").uniq)
    warnings.each { |w| create_brakeman_insight(w) }
  end

  def self.create_brakeman_insight(warning)
    create_insight(tool: :brakeman, severity: map_brakeman_confidence(warning["confidence"]),
                   message: warning["message"], file_path: warning["file"], line_number: warning["line"],
                   context: warning["code"])
  end

  def self.map_brakeman_confidence(confidence)
    case confidence
    when "High" then :critical
    when "Medium" then :warning
    else :advisory
    end
  end

  def self.ingest_rubocop(json_report)
    JSON.parse(json_report)["files"].each { |f| ingest_rubocop_file(f) }
  end

  def self.ingest_rubocop_file(file)
    deactivate(:rubocop, file["path"])
    file["offenses"].each { |o| create_rubocop_insight(file["path"], o) }
  end

  def self.create_rubocop_insight(path, offense)
    create_insight(tool: :rubocop, severity: map_rubocop_severity(offense["severity"]),
                   message: "[#{offense['cop_name']}] #{offense['message']}", file_path: path,
                   line_number: offense["location"]["line"])
  end

  def self.map_rubocop_severity(severity)
    case severity
    when "fatal", "error" then :critical
    when "warning" then :warning
    else :advisory
    end
  end

  def self.ingest_reek(json_report)
    JSON.parse(json_report).each { |smell| ingest_reek_smell(smell) }
  end

  def self.ingest_reek_smell(smell)
    smell["lines"].each { |line| create_reek_insight(smell, line) }
  end

  def self.create_reek_insight(smell, line)
    create_insight(tool: :reek, severity: :warning,
                   message: "[#{smell['smell_type']}] #{smell['context']} #{smell['message']}",
                   file_path: smell["source"], line_number: line)
  end

  def self.ingest_rails_best_practices(_yaml_report)
    # Rails Best Practices doesn't easily output JSON via CLI without extra gems
  end

  # update_all deliberately skips validations/callbacks -- this is a bulk
  # flag flip on prior insights, not a domain mutation that needs them.
  # rubocop:disable Rails/SkipsModelValidations
  def self.deactivate(tool, file_paths)
    SystemInsight.public_send(tool).where(file_path: file_paths).update_all(active: false)
  end
  # rubocop:enable Rails/SkipsModelValidations

  def self.create_insight(**attrs)
    SystemInsight.create!(**attrs, active: true)
  end
end
