# frozen_string_literal: true

require "digest"

# The single boundary for reading or building a ScenarioSignature#kind. Every
# consumer -- ReferenceDiff, HandshakeCheck, coverage, presentation -- classifies
# a kind through here instead of splitting the string inline. See ADR 009
# (docs/adr/009-reference-comparison-drift-and-coverage.md).
#
# Structural kinds are namespaced, "<namespace>:<identifier>":
#
#   field:work_authorization
#   screening_question:v1:<sha256 of normalized question text>
#   step:resolution.2
#   commitment_boundary:submit
#
# A kind with no namespace ("job_post_id") is a bare ATS identity and passes
# through unchanged. A namespace that isn't in STRUCTURAL_NAMESPACES is
# unknown_namespace: surfaced with a diagnostic, excluded from structural
# conclusions by callers, and raised in dev/test so vocabulary drift cannot land
# silently.
class Scenarios::SignatureKind
  STRUCTURAL_NAMESPACES = %w[field screening_question step commitment_boundary].freeze
  SCREENING_QUESTION_NAMESPACE = "screening_question"
  SCREENING_QUESTION_VERSION = "v1"

  class UnknownNamespaceError < StandardError; end

  Parsed = Data.define(:raw, :namespace, :identifier) do
    def classification
      return :ats_identity if namespace.nil?

      STRUCTURAL_NAMESPACES.include?(namespace) ? :structural : :unknown_namespace
    end

    def structural? = classification == :structural
    def ats_identity? = classification == :ats_identity
    def unknown_namespace? = classification == :unknown_namespace

    # Only meaningful for the screening_question namespace, whose identifier is
    # itself "<version>:<hash>".
    def screening_question_version = screening_question_parts&.first
    def screening_question_hash = screening_question_parts&.last

    def unknown_namespace_warning
      "[SignatureKind] unknown namespace #{namespace.inspect} in #{raw.inspect}"
    end

    private

    def screening_question_parts
      identifier.split(":", 2) if namespace == SCREENING_QUESTION_NAMESPACE
    end
  end

  # Parse a stored kind string. The only entry point for classification.
  def self.for(raw)
    parsed = split(raw.to_s)
    report_unknown(parsed) if parsed.unknown_namespace?
    parsed
  end

  # Build a structural kind string for a whitelisted namespace.
  def self.build(namespace, identifier)
    "#{validated_namespace(namespace)}:#{identifier}"
  end

  # Build the versioned normalized-text-hash kind for a screening question.
  # v1 normalization: trim, collapse internal whitespace, downcase.
  def self.screening_question(question_text)
    digest = Digest::SHA256.hexdigest(question_text.to_s.strip.gsub(/\s+/, " ").downcase)
    "#{SCREENING_QUESTION_NAMESPACE}:#{SCREENING_QUESTION_VERSION}:#{digest}"
  end

  def self.split(raw)
    namespace, identifier = raw.split(":", 2)
    return Parsed.new(raw: raw, namespace: nil, identifier: raw) if identifier.nil?

    Parsed.new(raw: raw, namespace: namespace, identifier: identifier)
  end
  private_class_method :split

  def self.validated_namespace(namespace)
    namespace.to_s.tap do |ns|
      raise ArgumentError, "unknown structural namespace: #{ns.inspect}" unless STRUCTURAL_NAMESPACES.include?(ns)
    end
  end
  private_class_method :validated_namespace

  def self.report_unknown(parsed)
    Rails.logger.warn(parsed.unknown_namespace_warning)
    raise UnknownNamespaceError, parsed.raw if Rails.env.local?
  end
  private_class_method :report_unknown
end
