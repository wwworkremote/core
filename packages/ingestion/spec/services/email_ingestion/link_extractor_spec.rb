# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailIngestion::LinkExtractor do
  let(:parsed_email) do
    {
      html_body: <<~HTML
        <html>
          <body>
            <a href="https://www.indeed.com/rc/clk?jk=12345">Indeed Job</a>
            <a href="https://www.linkedin.com/jobs/view/67890">LinkedIn Job</a>
            <a href="https://www.adzuna.com/details/111">Adzuna Job</a>
            <a href="https://www.indeed.com/preferences">Unsubscribe</a>
            <a href="https://www.google.com">Random Link</a>
          </body>
        </html>
      HTML
    }
  end

  describe "#call" do
    it "extracts only relevant job links for indeed" do
      extractor = described_class.new(parsed_email, "indeed")
      links = extractor.call
      expect(links).to include("https://www.indeed.com/rc/clk?jk=12345")
      expect(links).not_to include("https://www.google.com")
      expect(links).not_to include("https://www.indeed.com/preferences")
    end

    it "extracts only relevant job links for linkedin" do
      extractor = described_class.new(parsed_email, "linkedin")
      links = extractor.call
      expect(links).to include("https://www.linkedin.com/jobs/view/67890")
    end

    it "extracts and strips fragments from links in the text body" do
      text_email = { text_body: "Check this out: https://www.indeed.com/rc/clk?jk=999#section" }
      extractor = described_class.new(text_email, "indeed")

      expect(extractor.call).to include("https://www.indeed.com/rc/clk?jk=999")
    end

    it "silently drops malformed urls instead of raising" do
      bad_email = { text_body: "See https://www.indeed.com/rc/clk?jk=1 and not-a-url://[bad" }

      expect { described_class.new(bad_email, "indeed").call }.not_to raise_error
    end
  end
end
