# frozen_string_literal: true

require "rails_helper"

RSpec.describe StandingCriteria do
  def point_at(path)
    stub_const("#{described_class}::CONFIG_PATH", Pathname(path))
  end

  it "reads the bulleted criteria from the config file" do
    file = Tempfile.new(["criteria", ".yml"])
    file.write("criteria:\n  - \"Floor is X\"\n  - \"Culture over comp\"\n")
    file.close
    point_at(file.path)

    expect(described_class.lines).to eq(["Floor is X", "Culture over comp"])
    expect(described_class.prompt_block).to eq("- Floor is X\n- Culture over comp")
  ensure
    file.unlink
  end

  it "falls back to a neutral, figure-free placeholder when the file is absent" do
    point_at("/no/such/job_search_criteria.yml")

    expect(described_class.lines).to eq(described_class::DEFAULT_LINES)
    expect(described_class.prompt_block).not_to match(/\$\d/)
  end
end
