# frozen_string_literal: true

# Handles the "plain service object fetcher" strategy for
# DataAcquisitionManager.run -- one of its three run_* dispatch targets,
# split out alongside CrawlRunner to keep DataAcquisitionManager itself
# under Metrics/ClassLength.
class DataAcquisitionManager::ServiceRunner
  def self.call(slug, config, force)
    fetcher = config[:class].new
    call_args = build_call_args(config[:class], slug, force)
    result = normalize_result(invoke_fetcher(fetcher, call_args))
    sync_after_success(slug) if result[:success]
    result
  end

  def self.invoke_fetcher(fetcher, call_args)
    call_args.any? ? fetcher.call(**call_args) : fetcher.call
  end

  def self.build_call_args(fetcher_class, slug, force)
    parameters = fetcher_class.instance_method(:call).parameters
    args = {}
    args[:force] = force if accepts_force?(parameters)
    args[:source] = slug.split("_").last if email_source?(slug, parameters)
    args
  end

  def self.accepts_force?(parameters)
    parameters.any? { |p| p[1] == :force }
  end

  def self.email_source?(slug, parameters)
    slug.start_with?("email_") && parameters.any? { |p| p[1] == :source }
  end

  def self.normalize_result(result_raw)
    return result_raw if result_raw.is_a?(Hash)
    return { success: false, error: "Fetcher reported failure" } if result_raw == false

    { success: true }
  end

  def self.sync_after_success(slug)
    return unless JobBoards::Syncer.new.call

    JobBoards::Source.find_by(slug: slug)&.update!(last_ingested_at: Time.current)
  end
end
