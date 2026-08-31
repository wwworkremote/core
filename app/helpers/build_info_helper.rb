# frozen_string_literal: true

# Nothing in the app depends on this — it's a build fingerprint so "which code
# is this?" is answerable from the running site (mirrors the extension's
# `WWWR EXT x.y.z` stamp). Resolved once at load: ENV override for deploys that
# don't ship .git, else the git checkout, else "unknown".
module BuildInfoHelper
  BUILD_INFO =
    ENV["APP_BUILD_INFO"].presence || begin
      sha  = `git rev-parse --short HEAD 2>/dev/null`.strip
      date = `git log -1 --format=%cs 2>/dev/null`.strip
      sha.present? ? [sha, date].compact_blank.join(" · ") : "unknown"
    rescue StandardError
      "unknown"
    end

  def app_build_info = BUILD_INFO
end
