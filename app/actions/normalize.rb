# frozen_string_literal: true

class Normalize
  def initialize(text)
    @text = text
  end

  def call
    @call ||= self.class.normalize(text)

    self
  end

  def self.normalize(text)
    ActionController::Base \
      .helpers
      .strip_tags(Sanitize.fragment(RubyPants.new(text.downcase.strip, stupefy: true).to_html))
      .gsub(/&lt;/, '<')
      .gsub(/&gt;/, '>')
      .gsub(/&amp;/, '&')
      .gsub(/[[:space:]]+/, ' ')
      .strip
      .downcase
  end
end
