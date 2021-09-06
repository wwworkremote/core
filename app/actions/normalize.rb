# frozen_string_literal: true

require 'ostruct'
require 'sanitize'
require 'rubypants'

class Normalize
  attr_reader :parameters

  def initialize(text)
    @parameters = { text: text.freeze }.freeze
  end

  def call
    result unless @call
    @call = true
    freeze
  end

  def result
    @result ||= self.class.normalize(parameters[:text]).freeze
  end

  def self.normalize(text)
    ActionController::Base \
      .helpers
      .strip_tags(Sanitize.fragment(RubyPants.new(text.downcase.strip, stupefy: true).to_html))
      .gsub(/[[:space:]]+/, ' ')
      .gsub(/&lt;/, '<')
      .gsub(/&gt;/, '>')
      .gsub(/&amp;/, '&')
      .strip
  end
end
