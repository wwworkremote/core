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
    it_behaves_like "a valid job extraction", "indeed", <<~HTML
      <html>
        <body>
          <h1 class="jobsearch-JobInfoHeader-title">Senior Ruby Developer</h1>
          <div id="jobDescriptionText">We are looking for a Rubyist...</div>
        </body>
      </html>
    HTML
  end

  describe "Adzuna Contract" do
    it_behaves_like "a valid job extraction", "adzuna", <<~HTML
      <html>
        <body>
          <h1>Lead Ruby Engineer</h1>
          <div class="company">RemoteOps</div>
          <div class="location">UK</div>
          <div class="job-description">Apply now!</div>
        </body>
      </html>
    HTML
  end

  describe "Remotive Contract" do
    it_behaves_like "a valid job extraction", "remotive", <<~HTML
      <html>
        <body>
          <h1>Rails Backend</h1>
          <div class="company-name">RemotiveCo</div>
          <div class="location">Worldwide</div>
          <div class="job-description">Great job.</div>
        </body>
      </html>
    HTML
  end

  describe "WWR Contract" do
    it_behaves_like "a valid job extraction", "wwr", <<~HTML
      <html>
        <body>
          <h1>Senior Dev</h1>
          <div class="company-card"><a>WWR Team</a></div>
          <div class="location">Remote</div>
          <div class="job-body">Join us.</div>
        </body>
      </html>
    HTML
  end

  describe "BuiltIn Contract" do
    it_behaves_like "a valid job extraction", "builtin", <<~HTML
      <html>
        <body>
          <h1 class="node-title">Product Manager</h1>
          <div class="company-title">BuiltCorp</div>
          <div class="job-location">Chicago</div>
          <div class="job-description">Build things.</div>
        </body>
      </html>
    HTML
  end

  describe "Arbeitnow Contract" do
    it_behaves_like "a valid job extraction", "arbeitnow", <<~HTML
      <html>
        <body>
          <h1>Backend Dev</h1>
          <div class="company-name">BerlinTech</div>
          <div class="location">Berlin</div>
          <div class="job-description">Code now.</div>
        </body>
      </html>
    HTML
  end

  describe "RemoteIO Contract" do
    it_behaves_like "a valid job extraction", "remoteio", <<~HTML
      <html>
        <body>
          <h1>SRE</h1>
          <div class="company-name">CloudOps</div>
          <div class="job-description">Maintain scale.</div>
        </body>
      </html>
    HTML
  end

  describe "EchoJobs Contract" do
    it_behaves_like "a valid job extraction", "echojobs", <<~HTML
      <html>
        <body>
          <h1>Go Engineer</h1>
          <div class="company-name">StreamCo</div>
          <div class="location">Remote</div>
          <div class="job-description">Streaming stuff.</div>
        </body>
      </html>
    HTML
  end

  describe "LinkedIn Contract" do
    it_behaves_like "a valid job extraction", "linkedin", <<~HTML
      <html>
        <body>
          <h1 class="top-card-layout__title">Staff Software Engineer</h1>
          <div class="description__text">Build the future of remote work...</div>
        </body>
      </html>
    HTML
  end

  describe "Dice Contract" do
    it_behaves_like "a valid job extraction", "dice", <<~HTML
      <html>
        <body>
          <h1 id="jobTitle">Backend Lead</h1>
          <div id="jobDescription">Expert in Postgres and Vector search.</div>
        </body>
      </html>
    HTML
  end

  describe "Glassdoor Contract" do
    it_behaves_like "a valid job extraction", "glassdoor", <<~HTML
      <html>
        <body>
          <div class="JobDetails_jobTitle__Rwpro">Frontend Engineer</div>
          <div class="JobDetails_companyName__ksNxn">RemoteCo</div>
          <div class="JobDetails_jobDescriptionWrapper__j9vYp">React and Tailwind expertise required.</div>
        </body>
      </html>
    HTML
  end
end
