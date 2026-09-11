# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Docs" do
  describe "GET /docs" do
    it "lists real markdown files from the docs tree" do
      get docs_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("index")
    end
  end

  describe "GET /docs/*path" do
    it "renders a real doc's content as HTML" do
      get doc_path(path: "index.md")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Documentation Index")
    end

    it "renders a Mermaid diagram as an unwrapped .mermaid element, not an escaped <code> block" do
      get doc_path(path: "architecture/pipeline-statechart.md")

      expect(response).to have_http_status(:ok)
      # A real <code class="mermaid"> block (fenced-code's default) would
      # mean the extraction/reinsertion pipeline never ran -- <pre
      # class="mermaid"> with no nested <code> is the shape mermaid.js
      # expects. HTML-entity-escaped content (&gt; for a literal >) is
      # correct here, not a bug: the browser decodes it back to ">" when
      # computing .textContent, same as any other <pre> content.
      expect(response.body).to include('<pre class="mermaid">stateDiagram-v2')
      expect(response.body).not_to include('<pre class="mermaid"><code')
    end

    it "404s for a path outside the docs directory (path traversal)" do
      get doc_path(path: "../config/database.yml")

      expect(response).to have_http_status(:not_found)
    end

    it "404s for a path traversal attempt disguised inside a nested segment" do
      get doc_path(path: "architecture/../../../etc/passwd")

      expect(response).to have_http_status(:not_found)
    end

    it "404s for a file that isn't markdown" do
      get doc_path(path: "architecture/openapi.yaml")

      expect(response).to have_http_status(:not_found)
    end

    it "404s for a markdown-suffixed path that doesn't exist" do
      get doc_path(path: "does/not/exist.md")

      expect(response).to have_http_status(:not_found)
    end
  end
end
