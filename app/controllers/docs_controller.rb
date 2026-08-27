# frozen_string_literal: true

# Browses docs/**/*.md from inside the running app. params[:path] is an
# attacker-controlled URL segment, so resolve_path must verify the
# *expanded* real path is still inside DOCS_ROOT before ever touching the
# filesystem -- a string-prefix check on the unresolved path alone would
# be defeated by "..".
class DocsController < ApplicationController
  DOCS_ROOT = Rails.root.join("docs").freeze

  # Rails derives request.format from a recognized extension in the *raw
  # request path* (registered here as text/markdown, presumably by
  # Redcarpet or another gem) independently of routing -- format: false on
  # the route stops params[:format] from being set, but doesn't stop this,
  # so "/docs/index.md" still tries to render show.text.markdown.erb
  # without this override.
  before_action { request.format = :html }

  def index
    @entries = Dir.glob(DOCS_ROOT.join("**/*.md")).map { |path|
      Pathname.new(path).relative_path_from(DOCS_ROOT).to_s
    }.sort
  end

  def show
    @relative_path = params[:path].to_s
    absolute_path = resolve_path(@relative_path)
    return render(plain: "Not found", status: :not_found) unless absolute_path

    @html = render_markdown(absolute_path)
  end

  private

  def render_markdown(absolute_path)
    current_dir = Pathname.new(@relative_path).dirname.to_s
    DocsMarkdownRenderer.render(File.read(absolute_path), current_dir: current_dir)
  end

  def resolve_path(relative_path)
    return nil if relative_path.blank?

    candidate = DOCS_ROOT.join(relative_path).expand_path
    return nil unless within_docs_root?(candidate) && markdown_file?(candidate)

    candidate
  end

  def within_docs_root?(candidate)
    candidate.to_s.start_with?("#{DOCS_ROOT}/")
  end

  def markdown_file?(candidate)
    candidate.extname == ".md" && File.file?(candidate)
  end
end
