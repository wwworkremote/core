# frozen_string_literal: true

module Quality
  class InsightIngester
    def self.ingest_brakeman(json_report)
      data = JSON.parse(json_report)
      
      # Mark old brakeman insights as inactive for files mentioned in this report
      files = data['warnings'].map { |w| w['file'] }.uniq
      SystemInsight.brakeman.where(file_path: files).update_all(active: false)

      data['warnings'].each do |w|
        insight = SystemInsight.create!(
          tool: :brakeman,
          severity: map_brakeman_confidence(w['confidence']),
          message: w['message'],
          file_path: w['file'],
          line_number: w['line'],
          context: w['code'],
          active: true
        )
        
        # In a real scenario, we would trigger an embedding job here
        # Quality::InsightEmbeddingJob.perform_later(insight.id)
      end
    end

    def self.map_brakeman_confidence(confidence)
      case confidence
      when 'High' then :critical
      when 'Medium' then :warning
      else :advisory
      end
    end

    def self.ingest_rubocop(json_report)
      data = JSON.parse(json_report)
      
      data['files'].each do |f|
        path = f['path']
        SystemInsight.rubocop.where(file_path: path).update_all(active: false)
        
        f['offenses'].each do |o|
          SystemInsight.create!(
            tool: :rubocop,
            severity: map_rubocop_severity(o['severity']),
            message: "[#{o['cop_name']}] #{o['message']}",
            file_path: path,
            line_number: o['location']['line'],
            active: true
          )
        end
      end
    end

    def self.ingest_reek(json_report)
      data = JSON.parse(json_report)
      
      data.each do |smell|
        smell['lines'].each do |line|
          SystemInsight.create!(
            tool: :reek,
            severity: :warning,
            message: "[#{smell['smell_type']}] #{smell['context']} #{smell['message']}",
            file_path: smell['source'],
            line_number: line,
            active: true
          )
        end
      end
    end

    def self.ingest_rails_best_practices(yaml_report)
      # Rails Best Practices doesn't easily output JSON via CLI without extra gems, 
      # but we can parse its default output if we pipe it or use a temp file.
      # For now, let's assume we pass a simplified structure or parse the strings.
    end
