# frozen_string_literal: true

module ApplicationHelper
  include Heroicon::Engine.helpers

  def markdown(text)
    return "" if text.blank?

    options = {
      filter_html: true,
      hard_wrap: true,
      link_attributes: { target: "_blank", rel: "noopener noreferrer",
                         class: "text-violet-400 hover:text-violet-300 underline underline-offset-4" }
    }

    extensions = {
      autolink: true,
      no_intra_emphasis: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true
    }

    renderer = Redcarpet::Render::HTML.new(options)
    markdown = Redcarpet::Markdown.new(renderer, extensions)

    markdown.render(text).html_safe
  end
end
