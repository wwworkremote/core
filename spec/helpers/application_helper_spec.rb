# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#markdown" do
    it "renders markdown as HTML" do
      text = "# Hello World"
      expect(helper.markdown(text)).to include("<h1>Hello World</h1>")
    end

    it "renders links with specific attributes" do
      text = "[Google](https://google.com)"
      html = helper.markdown(text)
      expect(html).to include('target="_blank"')
      expect(html).to include('rel="noopener noreferrer"')
      expect(html).to include('class="text-violet-400')
    end

    it "filters HTML tags from raw input" do
      text = "<script>alert(1)</script> **Bold**"
      html = helper.markdown(text)
      expect(html).not_to include("<script>")
      expect(html).to include("<strong>Bold</strong>")
    end

    it "returns empty string for nil" do
      expect(helper.markdown(nil)).to eq("")
    end
  end
end
