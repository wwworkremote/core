# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobFetchers::UrlResolver do
  describe ".resolve" do
    context "LinkedIn URLs" do
      it "canonicalizes standard view URLs" do
        url = "https://www.linkedin.com/jobs/view/123456789/?refId=abc"
        expect(described_class.resolve(url)).to eq("https://www.linkedin.com/jobs/view/123456789")
      end

      it "canonicalizes communication/tracking URLs" do
        url = "https://www.linkedin.com/comm/jobs/view/987654321?trackingId=xyz"
        expect(described_class.resolve(url)).to eq("https://www.linkedin.com/jobs/view/987654321")
      end

      it "returns original if no ID match" do
        url = "https://www.linkedin.com/feed/"
        expect(described_class.resolve(url)).to eq(url)
      end
    end

    context "Indeed URLs" do
      it "canonicalizes viewjob URLs with jk parameter" do
        url = "https://www.indeed.com/viewjob?jk=abcdef12345&from=serp"
        expect(described_class.resolve(url)).to eq("https://www.indeed.com/viewjob?jk=abcdef12345")
      end

      it "returns original if no jk parameter" do
        url = "https://www.indeed.com/jobs?q=ruby"
        expect(described_class.resolve(url)).to eq(url)
      end
    end

    context "Generic URLs" do
      let(:short_url) { "http://bit.ly/job-link" }
      let(:target_url) { "https://company.com/careers/listing" }

      it "follows redirects using HEAD requests" do
        stub_request(:head, short_url)
          .to_return(status: 301, headers: { "location" => target_url })

        expect(described_class.resolve(short_url)).to eq(target_url)
      end

      it "returns original URL if no redirect found" do
        stub_request(:head, target_url).to_return(status: 200)
        expect(described_class.resolve(target_url)).to eq(target_url)
      end

      it "gracefully handles connection errors" do
        stub_request(:head, short_url).to_raise(Faraday::ConnectionFailed.new("Error"))
        expect(described_class.resolve(short_url)).to eq(short_url)
      end
    end
  end
end
