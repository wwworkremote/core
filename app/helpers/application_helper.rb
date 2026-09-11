# frozen_string_literal: true

module ApplicationHelper
  include Heroicon::Engine.helpers

  def markdown(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(markdown_render_options)
    markdown = Redcarpet::Markdown.new(renderer, markdown_extensions)

    # Safe: filter_html: true strips raw HTML from the source before
    # Redcarpet renders it, so the output here is sanitized markdown.
    # rubocop:disable Rails/OutputSafety
    markdown.render(text).html_safe
    # rubocop:enable Rails/OutputSafety
  end

  private

  # One cohesive options hash -- splitting it further would obscure it,
  # not simplify it.
  # rubocop:disable Metrics/MethodLength
  def markdown_render_options
    {
      filter_html: true,
      hard_wrap: true,
      link_attributes: { target: "_blank", rel: "noopener noreferrer",
                         class: "text-violet-400 hover:text-violet-300 underline underline-offset-4" }
    }
  end
  # rubocop:enable Metrics/MethodLength

  # One cohesive extensions hash -- splitting it further would obscure
  # it, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def markdown_extensions
    {
      autolink: true,
      no_intra_emphasis: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
      tables: true
    }
  end
  # rubocop:enable Metrics/MethodLength
end
