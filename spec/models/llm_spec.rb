# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'LLM Models loading', type: :model do
  it 'can load LLMChat' do
    expect { LLMChat }.not_to raise_error
  end

  it 'can load LLMMessage' do
    expect { LLMMessage }.not_to raise_error
  end

  it 'can load Model' do
    expect { Model }.not_to raise_error
  end
end
