# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LLM::JobSchedulerInspector do
  describe '.call' do
    it 'returns a hash with utility and pipeline groups' do
      result = described_class.call
      expect(result).to have_key(:utilities)
      expect(result).to have_key(:pipeline)
    end

    it 'includes core pipeline tasks' do
      result = described_class.call
      pipeline_ids = result[:pipeline].map { |t| t[:id] }
      expect(pipeline_ids).to include('fetch_all_jobs')
    end
  end
end
