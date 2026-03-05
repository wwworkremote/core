# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'LLM Models loading', type: :model do
  it 'can load LlmChat' do
    expect { LlmChat }.not_to raise_error
  end

  it 'can load LlmMessage' do
    expect { LlmMessage }.not_to raise_error
  end

  it 'can load Model' do
    expect { Model }.not_to raise_error
  end
end
