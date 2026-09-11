# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: extraction_rules
#
#  id          :bigint           not null, primary key
#  field_name  :string           not null
#  provider    :string           not null
#  sample_html :text
#  selector    :string           not null
#  source_url  :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_extraction_rules_on_provider_and_field_name  (provider,field_name) UNIQUE
#
RSpec.describe ExtractionRule do
  it "requires provider, field_name, and selector" do
    rule = described_class.new
    expect(rule).not_to be_valid
    expect(rule.errors.attribute_names).to include(:provider, :field_name, :selector)
  end

  it "is unique on [provider, field_name] but allows the same field on different providers" do
    create(:extraction_rule, provider: "linkedin", field_name: "title")

    dup = build(:extraction_rule, provider: "linkedin", field_name: "title")
    expect(dup).not_to be_valid

    other_provider = build(:extraction_rule, provider: "indeed", field_name: "title")
    expect(other_provider).to be_valid
  end

  it "upserts via find_or_initialize_by, replacing the selector on re-teach" do
    create(:extraction_rule, provider: "linkedin", field_name: "title", selector: "h1.old")

    rule = described_class.find_or_initialize_by(provider: "linkedin", field_name: "title")
    rule.update!(selector: "h1.new")

    expect(described_class.where(provider: "linkedin", field_name: "title").count).to eq(1)
    expect(described_class.find_by(provider: "linkedin", field_name: "title").selector).to eq("h1.new")
  end
end
