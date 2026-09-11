# frozen_string_literal: true

# Per-provider field extraction selectors for JobFetchers::CanonicalJobExtractor.
# A value is either a CSS selector (tried alone), an array of selectors (tried
# in order, first present match wins), or a Symbol naming a method on the
# extractor for anything that isn't a plain selector lookup (a static value,
# or a non-default Nokogiri pick).
module JobFetchers::CanonicalJobExtractor::Selectors
  FIELD_SELECTORS = {
    "indeed" => {
      title: ["h1.jobsearch-JobInfoHeader-title", "h1"],
      company: '[data-company-name="true"], .jobsearch-InlineCompanyRating div',
      location: :indeed_location,
      description: ["#jobDescriptionText", ".jobsearch-JobComponent-description"]
    },
    "linkedin" => {
      title: ["h1.top-card-layout__title", "h1"],
      company: ".topcard__org-name-link, .top-card-layout__first-subline a",
      location: ".topcard__flavor--bullet, .top-card-layout__first-subline .topcard__flavor",
      description: ".description__text, .show-more-less-html__markup"
    },
    "adzuna" => {
      title: "h1", company: ".company", location: ".location", description: ".job-description"
    },
    "glassdoor" => {
      title: ["div.JobDetails_jobTitle__Rwpro", "h1"],
      company: "div.JobDetails_companyName__ksNxn",
      location: "div.JobDetails_location__mSAsu",
      description: ["div.JobDetails_jobDescriptionWrapper__j9vYp", ".desc"]
    },
    "dice" => {
      title: ["h1#jobTitle", "h1"],
      company: ["a#companyDesignation", '[data-cy="companyName"]'],
      location: ["li.location", '[data-cy="location"]'],
      description: ["#jobDescription", ".job-details"]
    },
    "remotive" => {
      title: "h1", company: ".company-name", location: ".location", description: ".job-description"
    },
    "wwr" => {
      title: "h1", company: ".company-card a", location: ".location", description: ".job-body"
    },
    "arbeitnow" => {
      title: "h1", company: ".company-name", location: ".location", description: ".job-description"
    },
    "builtin" => {
      title: ["h1.node-title", "h1"],
      company: ".company-title",
      location: ".job-location",
      description: ".job-description"
    },
    "remoteio" => {
      title: "h1", company: ".company-name", location: :static_remote, description: ".job-description"
    },
    "echojobs" => {
      title: "h1", company: ".company-name", location: ".location", description: ".job-description"
    }
  }.freeze

  GENERIC_SELECTORS = {
    title: "h1", company: nil, location: nil, description: ["article, .description, .job-description", "body"]
  }.freeze
end
