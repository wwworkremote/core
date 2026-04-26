# frozen_string_literal: true

require "nokogiri"

class JobFetchers::CanonicalJobExtractor
  def initialize(html, url, provider)
    @doc = Nokogiri::HTML(html)
    @url = url
    @provider = provider
  end

  def call
    case @provider
    when "indeed"
      extract_indeed
    when "linkedin"
      extract_linkedin
    when "adzuna"
      extract_adzuna
    when "glassdoor"
      extract_glassdoor
    when "dice"
      extract_dice
    when "remotive"
      extract_remotive
    when "wwr"
      extract_wwr
    when "arbeitnow"
      extract_arbeitnow
    else
      extract_generic
    end
  end

  private

  def extract_remotive
    extract_generic
  end

  def extract_wwr
    extract_generic
  end

  def extract_arbeitnow
    extract_generic
  end

  def extract_glassdoor
    {
      title: @doc.css("div.JobDetails_jobTitle__Rwpro").text.strip.presence || @doc.css("h1").first&.text&.strip,
      company: @doc.css("div.JobDetails_companyName__ksNxn").first&.text&.strip,
      location: @doc.css("div.JobDetails_location__mSAsu").first&.text&.strip,
      description: @doc.css("div.JobDetails_jobDescriptionWrapper__j9vYp").inner_html.presence ||
                   @doc.css(".desc").inner_html,
      url: @url
    }
  end

  def extract_dice
    {
      title: @doc.css("h1#jobTitle").text.strip.presence || @doc.css("h1").first&.text&.strip,
      company: @doc.css("a#companyDesignation").text.strip.presence || @doc.css('[data-cy="companyName"]').text.strip,
      location: @doc.css("li.location").text.strip.presence || @doc.css('[data-cy="location"]').text.strip,
      description: @doc.css("#jobDescription").inner_html.presence || @doc.css(".job-details").inner_html,
      url: @url
    }
  end

  def extract_indeed
    {
      title: @doc.css("h1.jobsearch-JobInfoHeader-title").text.strip.presence || @doc.css("h1").first&.text&.strip,
      company: @doc.css('[data-company-name="true"], .jobsearch-InlineCompanyRating div').first&.text&.strip,
      location: @doc.css(".jobsearch-JobInfoHeader-subtitle div").last&.text&.strip,
      description: @doc.css("#jobDescriptionText").inner_html.presence ||
                   @doc.css(".jobsearch-JobComponent-description").inner_html,
      url: @url
    }
  end

  def extract_linkedin
    {
      title: @doc.css("h1.top-card-layout__title").text.strip.presence || @doc.css("h1").first&.text&.strip,
      company: @doc.css(".topcard__org-name-link, .top-card-layout__first-subline a").first&.text&.strip,
      location: @doc.css(".topcard__flavor--bullet, .top-card-layout__first-subline .topcard__flavor").first&.text&.strip,
      description: @doc.css(".description__text, .show-more-less-html__markup").inner_html,
      url: @url
    }
  end

  def extract_adzuna
    {
      title: @doc.css("h1").first&.text&.strip,
      company: @doc.css(".company").text.strip,
      location: @doc.css(".location").text.strip,
      description: @doc.css(".job-description").inner_html,
      url: @url
    }
  end

  def extract_generic
    {
      title: @doc.css("h1").first&.text&.strip,
      company: nil,
      location: nil,
      description: @doc.css("article, .description, .job-description").inner_html.presence ||
                   @doc.css("body").inner_html,
      url: @url
    }
  end
end
