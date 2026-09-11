# frozen_string_literal: true

require "fileutils"

# `bin/wwwr interview-prep <job_posting_id> [--regenerate] [--spoken] [--export[=<role>]]`
# Prints the stored interview prep pack for a posting, or generates one.
# `--spoken` prints the read-aloud version instead of the human one.
# `--export` writes both versions to ~/ai/outbox/wwwr/interview-prep/<role>/
# (role = the --export value, or the company name parameterized). Split out
# of Wwwr::CLI to keep that class under Metrics/ClassLength. Single-user app,
# so the pack is read/written against User.sole's UserJobPosting, same
# assumption Wwwr::Interop already makes.
class Wwwr::InterviewPrep
  EXPORT_ROOT = Pathname(Dir.home).join("ai/outbox/wwwr/interview-prep")

  def self.call(posting, regenerate: false, spoken: false, export: nil)
    new(posting, regenerate, spoken, export).call
  end

  def initialize(posting, regenerate, spoken, export)
    @posting = posting
    @regenerate = regenerate
    @spoken = spoken
    @export = export
  end

  def call
    generate unless fresh_pack_exists?
    return @error if @error
    return export_files if @export

    printed_pack
  end

  private

  def fresh_pack_exists?
    record&.interview_prep_pack.present? && !@regenerate
  end

  # After a fresh generation prefer @generated (the human output just produced)
  # over the DB read; the read-aloud column is only available through the record.
  def printed_pack
    stored = @spoken ? record&.interview_prep_pack_spoken : (@generated || record&.interview_prep_pack)
    stored.to_s.presence || missing_hint
  end

  def export_files
    dir = EXPORT_ROOT.join(export_slug)
    FileUtils.mkdir_p(dir)
    written = export_map.filter_map { |name, body| write_file(dir, name, body) }
    "Exported to #{dir}:\n#{written.join("\n")}"
  end

  def export_map
    { "pack.md" => @generated || record&.interview_prep_pack,
      "pack.spoken.md" => spoken_with_metadata }
  end

  # Re-serialize the read-aloud frontmatter: system discovery keys first
  # (so a directory scan can identify and load the file), then the model's
  # content hints. Also repairs a malformed model block into valid YAML.
  def spoken_with_metadata
    return if record&.interview_prep_pack_spoken.blank?

    hints, body = record.spoken_pack_parts
    "#{YAML.dump(discovery_keys.merge(hints))}---\n#{body}"
  end

  # The read-aloud convention (docs/interview-prep/tts-readable-documentation.md):
  # format: read-aloud is the marker a text-to-speech tool detects; kind names
  # the document type without changing how it is processed.
  def discovery_keys
    { "format" => "read-aloud", "kind" => "interview-prep", "lang" => "en-US",
      "source" => @posting.target_url, "generated_at" => Time.current.utc.iso8601 }
  end

  def write_file(dir, name, body)
    return if body.blank?

    File.write(dir.join(name), body)
    "  #{name} (#{body.bytesize} bytes)"
  end

  def export_slug
    return @export if @export.is_a?(String)

    (@posting.company_name.presence || "posting-#{@posting.id}").parameterize
  end

  def generate
    result = LLM::InterviewPrepGenerator.call(User.sole, @posting, force: true)
    return @error = "Generation failed: #{result[:error]}" unless result[:success]

    @generated = result[:output]
  end

  def record
    User.sole.user_job_postings.find_by(job_posting: @posting)
  end

  def missing_hint
    @spoken ? "(no read-aloud version -- regenerate to build one)" : ""
  end
end
