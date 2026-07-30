# frozen_string_literal: true

require "rails_helper"

# A live external HTTP contract check, not a class under test --
# RSpec/DescribeClass doesn't apply. before(:all)/after(:all) toggle
# global VCR/WebMock state deliberately and symmetrically for the
# whole file, not per-example state that could leak.
# rubocop:disable RSpec/DescribeClass, RSpec/BeforeAfterAll
RSpec.describe "YC Scraper Contract", type: :contract do
  before(:all) do
    WebMock.allow_net_connect!
    VCR.turn_off!
  end

  after(:all) do
    VCR.turn_on!
    WebMock.disable_net_connect!
  end
  # rubocop:enable RSpec/BeforeAfterAll

  let(:url) { Yc::Scraper::BASE_URL }
  let(:headers) { Yc::Scraper::REQUEST_HEADERS }

  it "returns a successful response from Work at a Startup" do
    response = Faraday.get(url, nil, headers)
    expect(response.status).to eq(200)
  end

  it "contains the embedded JSON data-page attribute" do
    response = Faraday.get(url, nil, headers)
    doc = Nokogiri::HTML(response.body)
    data_attr = doc.at_css("div[data-page]")&.[]("data-page")

    expect(data_attr).to be_present

    json_data = JSON.parse(CGI.unescape_html(data_attr))
    expect(json_data).to have_key("props")
    expect(json_data["props"]).to have_key("jobs")

    jobs = json_data.dig("props", "jobs")
    expect(jobs).to be_an(Array)

    if jobs.any?
      job = jobs.first
      expect(job).to have_key("id")
      expect(job).to have_key("title")
      expect(job).to have_key("companyName")
    end
  end
end
# rubocop:enable RSpec/DescribeClass
