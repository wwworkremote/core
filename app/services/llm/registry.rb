# frozen_string_literal: true

class LLM::Registry
  CONFIG_PATH = Rails.root.join("config/models.yml")

  # @default_model_id memoizes a YAML config read; under a race, worst case
  # is two threads computing and assigning the same value -- not a
  # correctness hazard, so ThreadSafety/ClassInstanceVariable is disabled
  # rather than adding synchronization this doesn't need.
  # rubocop:disable ThreadSafety/ClassInstanceVariable
  def self.sync
    @default_model_id = nil
    return unless File.exist?(CONFIG_PATH)

    YAML.load_file(CONFIG_PATH)["models"].each { |model_id, attrs| sync_model(model_id, attrs) }
  end

  # One cohesive find_or_create_by! block -- splitting it further would
  # obscure it, not simplify it.
  # rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
  def self.sync_model(model_id, attrs)
    m = Model.find_or_create_by!(provider: attrs["provider"], model_id: model_id) do |m|
      m.name = attrs["name"]
      m.family = attrs["family"]
      m.context_window = attrs["context_window"]
      m.max_output_tokens = attrs["max_output_tokens"]
    end
    Rails.logger.info "[Registry] Synced model: #{m.model_id}"
  end

  def self.default_model_id
    @default_model_id ||= YAML.load_file(CONFIG_PATH).dig("defaults", "primary")
  end
  # rubocop:enable ThreadSafety/ClassInstanceVariable

  def self.default_model
    Model.find_by(model_id: default_model_id)
  end

  # A named default for one call site, e.g. `defaults.answer_generation`.
  # Returns nil when the key is unset or names a model that hasn't been
  # synced, so an unconfigured purpose falls through to the primary --
  # pointing one path at a different model shouldn't mean configuring every
  # other path, or breaking them all on a typo.
  def self.model_for(purpose)
    model_id = YAML.load_file(CONFIG_PATH).dig("defaults", purpose.to_s)
    return if model_id.blank?

    Model.find_by(model_id: model_id)
  end
end
