# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobFetchers::CanonicalJobExtractor do
  let(:url) { "https://example.com/job/123" }

  shared_examples "a valid job extraction" do |provider, html|
    it "successfully extracts critical fields for #{provider}" do
      extractor = described_class.new(html, url, provider)
      result = extractor.call

      expect(result[:title]).to be_present, "Title should be present for #{provider}"
      expect(result[:description] || result[:body]).to be_present, "Description should be present for #{provider}"
    end
  end

  describe "Indeed Contract" do
    let(:html) do
      <<~HTML
        <html>
          <body>
            <h1 class="jobsearch-JobInfoHeader-title">Senior Ruby Developer</h1>
            <div id="jobDescriptionText">We are looking for a Rubyist...</div>
          </body>
        </html>
      HTML
    end

    include_examples "a valid job extraction", "indeed", "<html><body><h1 class='jobsearch-JobInfoHeader-title'>Senior Ruby Developer</h1><div id='jobDescriptionText'>We are looking for a Rubyist...</div></body></html>"
  end

  describe "Adzuna Contract" do
    let(:html) { "<html><body><h1>Lead Ruby Engineer</h1><div class='company'>RemoteOps</div><div class='location'>UK</div><div class='job-description'>Apply now!</div></body></html>" }
    include_examples "a valid job extraction", "adzuna", "<html><body><h1>Lead Ruby Engineer</h1><div class='company'>RemoteOps</div><div class='location'>UK</div><div class='job-description'>Apply now!</div></body></html>"
  end

  describe "LinkedIn Contract" do
    let(:html) do
      <<~HTML
        <html>
          <body>
            <h1 class="top-card-layout__title">Staff Software Engineer</h1>
            <div class="description__text">Build the future of remote work...</div>
          </body>
        </html>
      HTML
    end

    include_examples "a valid job extraction", "linkedin", "<html><body><h1 class='top-card-layout__title'>Staff Software Engineer</h1><div class='description__text'>Build the future of remote work...</div></body></html>"
  end

  describe "Dice Contract" do
    let(:html) do
      <<~HTML
        <html>
          <body>
            <h1 id="jobTitle">Backend Lead</h1>
            <div id="jobDescription">Expert in Postgres and Vector search.</div>
          </body>
        </html>
      HTML
    end

    include_examples "a valid job extraction", "dice", "<html><body><h1 id='jobTitle'>Backend Lead</h1><div id='jobDescription'>Expert in Postgres and Vector search.</div></body></html>"
  end

  describe "Glassdoor Contract" do
    let(:html) do
      <<~HTML
        <html>
          <body>
            <div class="JobDetails_jobTitle__Rwpro">Frontend Engineer</div>
            <div class="JobDetails_companyName__ksNxn">RemoteCo</div>
            <div class="JobDetails_jobDescriptionWrapper__j9vYp">React and Tailwind expertise required.</div>
          </body>
        </html>
      HTML
    end

    include_examples "a valid job extraction", "glassdoor", "<html><body><div class='JobDetails_jobTitle__Rwpro'>Frontend Engineer</div><div class='JobDetails_jobDescriptionWrapper__j9vYp'>React and Tailwind...</div></body></html>"
  end
end
