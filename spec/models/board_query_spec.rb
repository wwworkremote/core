# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: board_queries
#
#  id           :bigint           not null, primary key
#  board_name   :string
#  priority     :integer
#  query_params :json
#  remote       :boolean
#  terms        :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
RSpec.describe BoardQuery do
  describe "#build_url" do
    it "dispatches to build_cord_url" do
      bq = build(:board_query, board_name: "cord", terms: ["Ruby"], query_params: {})
      expect(bq.build_url).to eq(bq.build_cord_url)
    end

    it "dispatches to build_linkedin_url" do
      bq = build(:board_query, board_name: "LinkedIn", terms: ["Ruby"], query_params: {})
      expect(bq.build_url).to eq(bq.build_linkedin_url)
    end

    it "dispatches to build_indeed_url" do
      bq = build(:board_query, board_name: "indeed", terms: ["Ruby"], query_params: {})
      expect(bq.build_url).to eq(bq.build_indeed_url)
    end

    it "dispatches to build_dice_url" do
      bq = build(:board_query, board_name: "dice", terms: ["Ruby"], query_params: {})
      expect(bq.build_url).to eq(bq.build_dice_url)
    end

    it "dispatches to build_remoteok_url" do
      bq = build(:board_query, board_name: "remoteok", terms: ["Ruby"], query_params: {})
      expect(bq.build_url).to eq(bq.build_remoteok_url)
    end

    it "returns nil for an unknown board" do
      bq = build(:board_query, board_name: "unknown-board", terms: ["Ruby"], query_params: {})
      expect(bq.build_url).to be_nil
    end
  end

  describe "#build_cord_url" do
    it "builds a base URL with sort and keyword filters" do
      bq = build(:board_query, terms: ["Ruby Engineer"], query_params: {})
      url = bq.build_cord_url

      expect(url).to start_with("https://cord.com/search/jobs/ruby-engineer?")
      expect(CGI.unescape(url)).to include('"a":"sortBy"').and include('"a":"keyword"')
    end

    it "adds a remote filter when remote is requested" do
      bq = build(:board_query, terms: ["Ruby"], query_params: { "remote" => true })
      expect(CGI.unescape(bq.build_cord_url)).to include('"a":"remote"')
    end

    it "adds a remote-location-country filter when country is present" do
      bq = build(:board_query, terms: ["Ruby"], query_params: { "remote" => true, "country" => "Canada" })
      expect(CGI.unescape(bq.build_cord_url)).to include('"a":"remoteLocationCountries"').and include("Canada")
    end

    it "does not add a country filter when not remote" do
      bq = build(:board_query, terms: ["Ruby"], query_params: { "remote" => false, "country" => "Canada" })
      expect(CGI.unescape(bq.build_cord_url)).not_to include('"a":"remoteLocationCountries"')
    end

    it "adds a seniority filter for each seniority level" do
      bq = build(:board_query, terms: ["Ruby"], query_params: { "seniority" => %w[senior staff] })
      unescaped = CGI.unescape(bq.build_cord_url)
      expect(unescaped).to include('"v":"senior"').and include('"v":"staff"')
    end

    it "adds a formatted min_salary filter" do
      bq = build(:board_query, terms: ["Ruby"], query_params: { "min_salary" => 120_000 })
      unescaped = CGI.unescape(bq.build_cord_url)
      expect(unescaped).to include('"l":"Min: £120,000"').and include('"v":120000')
    end
  end

  def query_hash(url)
    Rack::Utils.parse_nested_query(URI(url).query)
  end

  describe "#build_linkedin_url" do
    it "builds a URL with keyword and default location" do
      bq = build(:board_query, terms: ["Ruby"], query_params: {})
      expect(bq.build_linkedin_url).to start_with("https://www.linkedin.com/jobs/search/?")
      expect(query_hash(bq.build_linkedin_url)).to eq("keywords" => "Ruby", "location" => "United States")
    end

    it "adds the remote work-type filter when remote is requested" do
      bq = build(:board_query, terms: ["Ruby"], query_params: { "remote" => true, "location" => "Anywhere" })
      expect(query_hash(bq.build_linkedin_url)).to eq(
        "keywords" => "Ruby", "location" => "Anywhere", "f_WT" => "2"
      )
    end
  end

  describe "#build_indeed_url" do
    it "builds a URL with query and default location" do
      bq = build(:board_query, terms: ["Ruby"], query_params: {})
      expect(bq.build_indeed_url).to start_with("https://www.indeed.com/jobs?")
      expect(query_hash(bq.build_indeed_url)).to eq("q" => "Ruby", "l" => "Remote")
    end

    it "adds the remote attribute filter when remote is requested" do
      bq = build(:board_query, terms: ["Ruby"], query_params: { "remote" => true })
      expect(query_hash(bq.build_indeed_url)["sc"]).to eq("0kf:attr(DSQF7);")
    end
  end

  describe "#build_dice_url" do
    it "builds a URL with default search params" do
      bq = build(:board_query, terms: ["Ruby"], query_params: {})
      expect(bq.build_dice_url).to start_with("https://www.dice.com/jobs?")
      expect(query_hash(bq.build_dice_url)).to eq(
        "q" => "Ruby", "countryCode" => "US", "radius" => "30", "radiusUnit" => "mi",
        "page" => "1", "pageSize" => "20"
      )
    end

    it "adds the isRemote filter when remote is requested" do
      bq = build(:board_query, terms: ["Ruby"], query_params: { "remote" => true })
      expect(query_hash(bq.build_dice_url)["filters.isRemote"]).to eq("true")
    end
  end

  describe "#build_remoteok_url" do
    it "builds a URL from the parameterized keyword" do
      bq = build(:board_query, terms: ["Ruby Engineer"], query_params: {})
      expect(bq.build_remoteok_url).to eq("https://remoteok.com/remote-ruby-engineer-jobs")
    end
  end

  describe ".create_for_role_family!" do
    it "creates one row per alias in the family" do
      queries = described_class.create_for_role_family!(:staff_plus_ic, board_name: "indeed", query_params: {})

      expect(queries.size).to eq(RoleFamily.aliases_for(:staff_plus_ic).size)
      expect(queries.map(&:terms)).to eq(RoleFamily.aliases_for(:staff_plus_ic).zip)
    end

    it "produces distinct URLs across builders, avoiding idempotency-key collisions" do
      indeed_queries = described_class.create_for_role_family!(:engineering_management, board_name: "indeed",
                                                                                        query_params: {})
      dice_queries = described_class.create_for_role_family!(:engineering_management, board_name: "dice",
                                                                                      query_params: {})

      expect(indeed_queries.map(&:build_url).uniq.size).to eq(indeed_queries.size)
      expect(dice_queries.map(&:build_url).uniq.size).to eq(dice_queries.size)
    end

    it "leaves unrelated single-term BoardQuery rows unaffected" do
      untouched = create(:board_query, board_name: "cord", terms: ["Ruby"])

      described_class.create_for_role_family!(:data_leadership, board_name: "indeed", query_params: {})

      expect(untouched.reload.terms).to eq(["Ruby"])
    end
  end
end
