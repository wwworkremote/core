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

  def to_csv
    [result].to_csv if result
  end

  def to_s
    to_csv.to_s
  end

  def to_json
    result&.to_json
  end

  def self.normalize(text)
    return text if text.blank?

    ActionController::Base \
      .helpers
      .strip_tags(
        Sanitize.fragment(
          RubyPants.new(
            I18n.transliterate(
              text.downcase.strip.force_encoding('UTF-8').unicode_normalize(:nfkc),
              locale: :en
            ),
            stupefy: true
          ).to_html
        )
      )
      .gsub(/[[:space:]]+/, ' ')
      .gsub(/&lt;/, '<')
      .gsub(/&gt;/, '>')
      .gsub(/&amp;/, '&')
      .strip
  end
end
