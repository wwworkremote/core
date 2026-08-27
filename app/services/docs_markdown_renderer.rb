# frozen_string_literal: true

# Renders a docs/ markdown file to HTML for DocsController, handling two
# things Redcarpet doesn't do on its own: Mermaid diagram blocks (```mermaid
# fences need to survive as raw, unescaped text so the browser's mermaid.js
# can parse them -- not become HTML-escaped <code> content), and internal
# doc-to-doc links (a relative "development.md"-style link needs to route
# back through /docs/... instead of the browser trying to load a raw
# markdown file directly).
class DocsMarkdownRenderer
  MERMAID_FENCE = /```mermaid\n(.*?)```/m

  RENDERER = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML.new(hard_wrap: false),
    fenced_code_blocks: true, tables: true, autolink: true, no_intra_emphasis: true
  )

  def self.render(markdown, current_dir:)
    new(markdown, current_dir: current_dir).render
  end

  def initialize(markdown, current_dir:)
    @current_dir = current_dir
    @diagrams = []
    @markdown = extract_mermaid_blocks(markdown)
  end

  def render
    html = RENDERER.render(@markdown)
    html = rewrite_internal_links(html)
    reinsert_mermaid_blocks(html)
  end

  private

  # Pulled out of the markdown source before Redcarpet ever sees it, and
  # replaced with a placeholder comment -- otherwise fenced-code rendering
  # would HTML-escape the diagram syntax as <code> text, which mermaid.js
  # can't parse (it needs the raw `-->`/`[]`/etc characters, not entities).
  def extract_mermaid_blocks(markdown)
    markdown.gsub(MERMAID_FENCE) do
      @diagrams << Regexp.last_match(1)
      "\n\n<!--MERMAID_DIAGRAM_#{@diagrams.length - 1}-->\n\n"
    end
  end

  def reinsert_mermaid_blocks(html)
    @diagrams.each_with_index do |diagram, index|
      html = html.sub("<!--MERMAID_DIAGRAM_#{index}-->", %(<pre class="mermaid">#{CGI.escapeHTML(diagram)}</pre>))
    end
    html
  end

  # Only rewrites hrefs that look like a relative link to another markdown
  # file in this docs tree -- external links, anchors, and mailto: pass
  # through untouched.
  def rewrite_internal_links(html)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css("a[href]").each { |link|
      link["href"] = resolved_doc_href(link["href"]) if internal_doc_link?(link["href"])
    }
    doc.to_html
  end

  def internal_doc_link?(href)
    href.end_with?(".md") && !href.match?(%r{\A[a-z][a-z0-9+.-]*://}i) && !href.start_with?("/")
  end

  def resolved_doc_href(href)
    "/docs/#{Pathname.new(File.join(@current_dir, href)).cleanpath}"
  end
end
