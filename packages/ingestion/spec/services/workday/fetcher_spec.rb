# frozen_string_literal: true

require "rails_helper"

RSpec.describe Workday::Fetcher, type: :service do
  let(:service) { described_class.new }
  let(:board) { { "tenant" => "acme", "wd" => "wd1", "site" => "Careers" } }
  let(:source) { JobBoards::Source.find_or_create_by!(slug: "workday", name: "Workday") }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }

  def stub_list(postings)
    stub_request(:post, "https://acme.wd1.myworkdayjobs.com/wday/cxs/acme/Careers/jobs")
      .to_return(status: 200, body: { jobPostings: postings }.to_json)
  end

  describe "#fetch_granular" do
    it "skips a posting whose detail body is blank instead of raising, and still stores the rest" do
      stub_list([{ "externalPath" => "/job/bad" }, { "externalPath" => "/job/good" }])
      stub_request(:get, "https://acme.wd1.myworkdayjobs.com/wday/cxs/acme/Careers/job/bad")
        .to_return(status: 200, body: "")
      stub_request(:get, "https://acme.wd1.myworkdayjobs.com/wday/cxs/acme/Careers/job/good")
        .to_return(status: 200, body: { jobPostingInfo: { jobPostingId: "good", title: "Engineer" } }.to_json)

      expect { service.fetch_granular(board, "", source.id, query.id) }.not_to raise_error

      expect(JobBoards::Document.find_by(signature: "workday-acme/Careers-good")).to be_present
    end

    it "skips a posting whose detail body is non-JSON instead of raising" do
      stub_list([{ "externalPath" => "/job/bad" }])
      stub_request(:get, "https://acme.wd1.myworkdayjobs.com/wday/cxs/acme/Careers/job/bad")
        .to_return(status: 200, body: "<html>not json</html>")

      expect { service.fetch_granular(board, "", source.id, query.id) }.not_to raise_error
      expect(JobBoards::Document.count).to eq(0)
    end
  end
end
