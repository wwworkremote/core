# frozen_string_literal: true

require 'nokogiri'

module JobFetchers
  class CanonicalJobExtractor
    def initialize(html, url, provider)
      @doc = Nokogiri::HTML(html)
      @url = url
      @provider = provider
    end

    def call
      case @provider
      when 'indeed'
        extract_indeed
      when 'linkedin'
        extract_linkedin
      when 'adzuna'
        extract_adzuna
      else
        extract_generic
      end
    end

    private

    def extract_indeed
      {
        title: @doc.css('h1.jobsearch-JobInfoHeader-title').text.strip.presence || @doc.css('h1').first&.text&.strip,
        company: @doc.css('[data-company-name="true"], .jobsearch-InlineCompanyRating div').first&.text&.strip,
        location: @doc.css('.jobsearch-JobInfoHeader-subtitle div').last&.text&.strip,
        description: @doc.css('#jobDescriptionText').inner_html.presence || @doc.css('.jobsearch-JobComponent-description').inner_html,
        url: @url
      }
    end

    def extract_linkedin
      {
        title: @doc.css('h1.top-card-layout__title').text.strip.presence || @doc.css('h1').first&.text&.strip,
        company: @doc.css('.topcard__org-name-link, .top-card-layout__first-subline a').first&.text&.strip,
        location: @doc.css('.topcard__flavor--bullet, .top-card-layout__first-subline .topcard__flavor').first&.text&.strip,
        description: @doc.css('.description__text, .show-more-less-html__markup').inner_html,
        url: @url
      }
    end

    def extract_adzuna
      {
        title: @doc.css('h1').first&.text&.strip,
        company: @doc.css('.company').text.strip,
        location: @doc.css('.location').text.strip,
        description: @doc.css('.job-description').inner_html,
        url: @url
      }
    end

    def extract_generic
      {
        title: @doc.css('h1').first&.text&.strip,
        company: nil,
        location: nil,
        description: @doc.css('article, .description, .job-description').inner_html.presence || @doc.css('body').inner_html,
        url: @url
      }
    end
  end
end
