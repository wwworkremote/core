# frozen_string_literal: true

require 'csv'
require 'i18n'
require 'sanitize'
require 'rubypants'
require 'json'

# I18n.locale = :en

class Normalize
  attr_reader :params

  def initialize(text)
    @params = { text: text.freeze }.freeze
  end

  def call
    result unless @call
    @call = true
    self
  end

  def result
    @result ||= self.class.normalize(params[:text]).freeze
  end

  delegate :blank?, to: :result

  delegate :to_s, to: :result

  def to_json(*_args)
    result&.to_json
  end

  def self.normalize(text)
    return if text.blank?

    ActionController::Base \
      .helpers
      .strip_tags(Sanitize.fragment(RubyPants.new(text.strip.scrub.downcase, stupefy: true).to_html))
      .unicode_normalize(:nfkc)
      .gsub(/[[:space:]]+/, ' ')
      .gsub(/[^[:print:]]/, '')
      .gsub(/&amp;/, '&')
      .gsub(/&gt;/, '>')
      .gsub(/&lt;/, '<')
      .tr('–', '-')
      .tr('—', '-')
      .tr('‘', "'")
      .tr('’', "'")
      .tr('“', '"')
      .tr('”', '"')
      .tr('', '')
      .strip
  end
end

# .gsub(/(θ|ð)/, 'th')
# .gsub(/@/, '@')
# .gsub(/^[[:print:]]/, '')
# .gsub(/résumé/, 'resume')
# .gsub(/‍/, '')
# .localize.transliterate_into(:en)
# .scrub
# .tr("ü", 'u'),
# .tr('`’“”—–', '\'\'""--')
# .tr('ú', 'u')
# .tr('ü', 'u')
# .tr('', '')
# .unicode_normalize(:nfkc)
# text.downcase.strip.force_encoding('UTF-8').unicode_normalize(:nfkc),
# text.downcase.strip.force_encoding('UTF-8').unicode_normalize(:nfkc).localize.transliterate_into(:en),
