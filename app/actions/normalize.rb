# frozen_string_literal: true

require 'csv'
require 'i18n'
require 'sanitize'
require 'rubypants'
require 'json'

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

    I18n.locale = :en

    I18n.transliterate(
      ActionController::Base
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
      .strip,
      locale: :en
    )
  end
end

# .gsub(/aren't/, 'are not')
# .gsub(/can't/, 'cannot')
# .gsub(/didn't/, 'did not')
# .gsub(/doesn't/, 'does not')
# .gsub(/don't/, 'do not')
# .gsub(/hasn't/, 'has not')
# .gsub(/haven't/, 'have not')
# .gsub(/he's/, 'he is')
# .gsub(/i'll/, 'i will')
# .gsub(/i'm/, 'i am')
# .gsub(/i've/, 'i have')
# .gsub(/isn't/, 'is not')
# .gsub(/it'd/, 'it would')
# .gsub(/it'll/, 'it will')
# .gsub(/it's/, 'it is')
# .gsub(/let's/, 'let us')
# .gsub(/req'd/, 'required')
# .gsub(/s'more/, 'some more')
# .gsub(/shouldn't/, 'should not')
# .gsub(/that'd/, 'that would')
# .gsub(/that's/, 'that is')
# .gsub(/there's/, 'there is')
# .gsub(/they'll/, 'they will')
# .gsub(/they're/, 'they are')
# .gsub(/they've/, 'they have')
# .gsub(/wasn't/, 'was not')
# .gsub(/we'd/, 'we would')
# .gsub(/we'll/, 'we will')
# .gsub(/we're/, 'we are')
# .gsub(/we've/, 'we have')
# .gsub(/what's/, 'what is')
# .gsub(/who's/, 'who is')
# .gsub(/won't/, 'will not')
# .gsub(/wouldn't/, 'would not')
# .gsub(/ya'll/, 'you all')
# .gsub(/you'd/, 'you would')
# .gsub(/you'll/, 'you will')
# .gsub(/you're/, 'you are')
# .gsub(/you've/, 'you have')
