#!/usr/bin/env ruby
# frozen_string_literal: true

# Live capture -> promote verification for one job-board URL, bypassing the
# Chrome extension entirely. Fetches the real page, extracts fields the same
# way content.js's JSON-LD tier does (schema.org JobPosting), and drives
# POST /api/leads then POST /api/leads/:id/promote so the resulting
# JobPosting can be checked against the source.
#
# Two environment gotchas this exists to route around:
#
#   1. Chrome automation on this box can't reach the extension's side panel
#      -- documented in docs/extension-workflow.md. This script is the
#      sanctioned fallback path (see that doc) for verifying promote.
#   2. Local nginx's client_body_temp dir is unwritable (permission denied),
#      so any POST with a body nginx decides to buffer to disk (e.g. a
#      raw_html snapshot) 500s at the nginx layer before Rails ever sees it.
#      This script talks to Puma directly on --puma-port (see config/puma.rb),
#      skipping nginx.
#
# Usage:
#   bin/verify_promote.rb --provider lever --url "https://jobs.lever.co/ro/xxx"
#   bin/verify_promote.rb --provider workday --url "..." --title "..." --location "..." --employment-type "Full-time"
#
# Any --field override wins over what JSON-LD produced (some providers, e.g.
# Workday's SPA, don't render schema.org JSON-LD -- pass fields by hand).

require "net/http"
require "json"
require "uri"
require "optparse"

PROMOTE_DATA_KEYS = %w[
  salary_min salary_max salary_currency salary_unit salary
  employment_type remote experience valid_through
  education qualifications responsibilities benefits
  company_logo_url industry
].freeze

HTML_MAX_BYTES = 512 * 1024

opts = { data: {} }
OptionParser.new do |o|
  o.on("--provider PROVIDER") { |v| opts[:provider] = v }
  o.on("--url URL") { |v| opts[:url] = v }
  o.on("--title TITLE") { |v| opts[:title] = v }
  o.on("--company COMPANY") { |v| opts[:company] = v }
  o.on("--company-id ID", Integer) { |v| opts[:company_id] = v }
  o.on("--location LOCATION") { |v| opts[:location] = v }
  o.on("--apply-url URL") { |v| opts[:apply_url] = v }
  o.on("--body-file FILE") { |v| opts[:body] = File.read(v) }
  o.on("--employment-type TYPE") { |v| opts[:data]["employment_type"] = v }
  o.on("--salary-min N") { |v| opts[:data]["salary_min"] = v }
  o.on("--salary-max N") { |v| opts[:data]["salary_max"] = v }
  o.on("--salary-currency CUR") { |v| opts[:data]["salary_currency"] = v }
  o.on("--salary-unit UNIT") { |v| opts[:data]["salary_unit"] = v }
  o.on("--puma-port PORT", Integer, "default 31000") { |v| opts[:port] = v }
  o.on("--extract-only", "fetch + print extracted fields, don't capture/promote") { opts[:extract_only] = true }
end.parse!

abort "usage: bin/verify_promote.rb --provider X --url URL [--field overrides]" unless opts[:provider] && opts[:url]

def fetch(url)
  uri = URI(url)
  res = Net::HTTP.get_response(uri)
  raise "GET #{url} -> #{res.code}" unless res.is_a?(Net::HTTPSuccess)

  res.body.force_encoding("UTF-8")
end

# Mirrors extension/content.js Extractor.jsonLd -- first schema.org
# JobPosting found in a <script type="application/ld+json"> block.
def extract_json_ld(html)
  html.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).each do |(raw)|
    data = JSON.parse(raw)
    candidates = data.is_a?(Array) ? data : (data["@graph"] || [data])
    item = candidates.find { |c| c["@type"] == "JobPosting" }
    next unless item

    addr = item.dig("jobLocation", "address") || item.dig("jobLocation", 0, "address")
    loc = [addr["addressLocality"], addr["addressRegion"], addr["addressCountry"]].compact.join(", ") if addr
    salary = item["baseSalary"]
    salary_val = salary && salary["value"]
    desc_text = item["description"]&.gsub(/<[^>]+>/, " ")
    desc_text = desc_text&.gsub(/\s+/, " ")&.strip

    return {
      "title" => item["title"],
      "company" => item.dig("hiringOrganization", "name"),
      "company_logo_url" => item.dig("hiringOrganization", "logo"),
      "location" => loc,
      "employment_type" => item["employmentType"],
      "salary_min" => salary_val && salary_val["minValue"],
      "salary_max" => salary_val && salary_val["maxValue"],
      "salary_currency" => salary && salary["currency"],
      "salary_unit" => salary_val && salary_val["unitText"],
      "apply_url" => item["url"] || item["sameAs"],
      "description_text" => desc_text,
    }
  rescue JSON::ParserError
    next
  end
  {}
end

def post(port, path, payload)
  uri = URI("http://localhost:#{port}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
  req.body = JSON.generate(payload)
  res = http.request(req)
  begin
    [res.code, JSON.parse(res.body)]
  rescue JSON::ParserError
    [res.code, res.body[0..500]]
  end
end

port = opts[:port] || 31_000
html = fetch(opts[:url])
extracted = extract_json_ld(html)

# Explicit --flags win over JSON-LD.
title = opts[:title] || extracted["title"]
company = opts[:company] || extracted["company"]
location = opts[:location] || extracted["location"]
apply_url = opts[:apply_url] || extracted["apply_url"] || opts[:url]
body = opts[:body] || extracted["description_text"]
data = extracted.slice(*PROMOTE_DATA_KEYS).merge(opts[:data]).reject { |_, v| v.nil? || v == "" }

puts "Extracted from #{opts[:url]}:"
puts({ title:, company:, location:, apply_url:, data:, body_words: body.to_s.split.size }.to_json)

exit if opts[:extract_only]

truncated = html.bytesize > HTML_MAX_BYTES
raw_html = truncated ? html.byteslice(0, HTML_MAX_BYTES) : html

capture_payload = {
  url: opts[:url],
  provider: opts[:provider],
  title: title,
  company_name: company,
  location: location,
  raw_html: raw_html,
  discovery: { extraction_method: "json_ld", extraction_confidence: "high", field_count: data.size, referrer: "",
               search_context: "", html_truncated: truncated },
}
code, resp = post(port, "/api/leads", capture_payload)
puts "CAPTURE #{code}: #{resp}"
lead_id = resp.is_a?(Hash) ? resp["id"] : nil
abort "capture failed, aborting" unless lead_id

promote_payload = {
  title: title,
  location: location,
  target_url: apply_url,
  body: body,
  data: data,
}
if opts[:company_id]
  promote_payload[:company_id] = opts[:company_id]
elsif company
  promote_payload[:company] = { name: company }
end

code, resp = post(port, "/api/leads/#{lead_id}/promote", promote_payload)
puts "PROMOTE #{code}: #{resp}"
