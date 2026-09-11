# frozen_string_literal: true

require "rails_helper"

# Checks multiple model classes load, not one class under test --
# RSpec/DescribeClass doesn't apply.
# rubocop:disable RSpec/DescribeClass
RSpec.describe "LLM Models loading" do
  it "can load LLMChat" do
    expect { LLMChat }.not_to raise_error
  end

  it "can load LLMMessage" do
    expect { LLMMessage }.not_to raise_error
  end

  it "can load Model" do
    expect { Model }.not_to raise_error
  end
end
# rubocop:enable RSpec/DescribeClass
