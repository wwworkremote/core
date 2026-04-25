# frozen_string_literal: true

require 'yaml'

module Resume
  class YamlImporter
    DEFAULT_BASE_PATH = '/Users/mike/github.com/just3ws/just3ws.github.io/_data/resume'
    attr_reader :base_path

    def self.call(user, base_path: nil)
      new(user, base_path: base_path).call
    end

    def initialize(user, base_path: nil)
      @user = user
      @profile = user.career_profile || user.create_career_profile!
      @base_path = base_path || DEFAULT_BASE_PATH
    end

    def call
      ActiveRecord::Base.transaction do
        import_profile
        import_positions
        # Add other imports (skills, etc.) as needed
      end
      { success: true }
    end

    private

    def import_profile
      data = load_yaml('profile.yml')
      return unless data

      @user.update!(name: data['name'])
      @profile.update!(
        contact_info: data['contact'],
        location_info: data['location']
      )
    end

    def import_positions
      Dir.glob(File.join(@base_path, 'positions', '*.yml')).each do |file|
        data = YAML.load_file(file)
        next unless data

        external_id = data['id'] || File.basename(file, '.yml')

        exp = @profile.work_experiences.find_or_initialize_by(external_id: external_id)
        exp.update!(
          company_name: data.dig('company', 'name'),
          location: data.dig('company', 'location'),
          title: data['title'],
          employment_type: data['type'],
          start_date: parse_date(data['start_date']),
          end_date: parse_date(data['end_date']),
          context: data['context'],
          description: data['description'],
          summary: data['summary'],
          action: data['action'],
          impact: data['impact'],
          scope: data['scope']
        )

        # Import Highlights
        exp.experience_highlights.destroy_all
        Array(data['highlights']).each do |h|
          exp.experience_highlights.create!(
            label: h['label'],
            text: h['text']
          )
        end
      end
    end

    def parse_date(str)
      return nil if str.blank? || str.downcase == 'present'

      # Handle "September 2018"
      begin
        Date.parse(str)
      rescue Date::Error
        # Fallback for year only or other formats
        Date.new(str.to_i, 1, 1) if /^\d{4}$/.match?(str)
      end
    end

    def load_yaml(filename)
      path = File.join(@base_path, filename)
      return nil unless File.exist?(path)
      YAML.load_file(path)
    end
  end
end
