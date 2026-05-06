# frozen_string_literal: true

class LLM::Registry
  CONFIG_PATH = Rails.root.join("config/models.yml")

  def self.sync
    @default_model_id = nil
    return unless File.exist?(CONFIG_PATH)

    config = YAML.load_file(CONFIG_PATH)
    config["models"].each do |model_id, attrs|
      m = Model.find_or_create_by!(provider: attrs["provider"], model_id: model_id) do |m|
        m.name = attrs["name"]
        m.family = attrs["family"]
        m.context_window = attrs["context_window"]
        m.max_output_tokens = attrs["max_output_tokens"]
      end
      Rails.logger.info "[Registry] Synced model: #{m.model_id}"
    end
  end

  def self.default_model_id
    @default_model_id ||= YAML.load_file(CONFIG_PATH).dig("defaults", "primary")
  end

  def self.default_model
    Model.find_by(model_id: default_model_id)
  end
end
