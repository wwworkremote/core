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

  describe "Remotive Contract" do
    let(:html) { "<html><body><h1>Rails Backend</h1><div class='company-name'>RemotiveCo</div><div class='location'>Worldwide</div><div class='job-description'>Great job.</div></body></html>" }
    include_examples "a valid job extraction", "remotive", "<html><body><h1>Rails Backend</h1><div class='company-name'>RemotiveCo</div><div class='location'>Worldwide</div><div class='job-description'>Great job.</div></body></html>"
  end

  describe "WWR Contract" do
    let(:html) { "<html><body><h1>Senior Dev</h1><div class='company-card'><a>WWR Team</a></div><div class='location'>Remote</div><div class='job-body'>Join us.</div></body></html>" }
    include_examples "a valid job extraction", "wwr", "<html><body><h1>Senior Dev</h1><div class='company-card'><a>WWR Team</a></div><div class='location'>Remote</div><div class='job-body'>Join us.</div></body></html>"
  end

  describe "BuiltIn Contract" do
    let(:html) { "<html><body><h1 class='node-title'>Product Manager</h1><div class='company-title'>BuiltCorp</div><div class='job-location'>Chicago</div><div class='job-description'>Build things.</div></body></html>" }
    include_examples "a valid job extraction", "builtin", "<html><body><h1 class='node-title'>Product Manager</h1><div class='company-title'>BuiltCorp</div><div class='job-location'>Chicago</div><div class='job-description'>Build things.</div></body></html>"
  end

  describe "Arbeitnow Contract" do
    let(:html) { "<html><body><h1>Backend Dev</h1><div class='company-name'>BerlinTech</div><div class='location'>Berlin</div><div class='job-description'>Code now.</div></body></html>" }
    include_examples "a valid job extraction", "arbeitnow", "<html><body><h1>Backend Dev</h1><div class='company-name'>BerlinTech</div><div class='location'>Berlin</div><div class='job-description'>Code now.</div></body></html>"
  end

  describe "RemoteIO Contract" do
    let(:html) { "<html><body><h1>SRE</h1><div class='company-name'>CloudOps</div><div class='job-description'>Maintain scale.</div></body></html>" }
    include_examples "a valid job extraction", "remoteio", "<html><body><h1>SRE</h1><div class='company-name'>CloudOps</div><div class='job-description'>Maintain scale.</div></body></html>"
  end

  describe "EchoJobs Contract" do
    let(:html) { "<html><body><h1>Go Engineer</h1><div class='company-name'>StreamCo</div><div class='location'>Remote</div><div class='job-description'>Streaming stuff.</div></body></html>" }
    include_examples "a valid job extraction", "echojobs", "<html><body><h1>Go Engineer</h1><div class='company-name'>StreamCo</div><div class='location'>Remote</div><div class='job-description'>Streaming stuff.</div></body></html>"
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
