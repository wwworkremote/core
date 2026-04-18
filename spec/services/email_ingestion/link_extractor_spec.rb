# frozen_string_literal: true

require 'rails_helper'

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

  describe '#call' do
    it 'extracts only relevant job links for indeed' do
      extractor = described_class.new(parsed_email, 'indeed')
      links = extractor.call
      expect(links).to include('https://www.indeed.com/rc/clk?jk=12345')
      expect(links).not_to include('https://www.google.com')
      expect(links).not_to include('https://www.indeed.com/preferences')
    end

    it 'extracts only relevant job links for linkedin' do
      extractor = described_class.new(parsed_email, 'linkedin')
      links = extractor.call
      expect(links).to include('https://www.linkedin.com/jobs/view/67890')
    end
  end
end
