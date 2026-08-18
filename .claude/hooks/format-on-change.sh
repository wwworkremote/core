#!/usr/bin/env bash
# PostToolUse hook: auto-fix formatting/lint issues on files just edited/written,
# so violations surface immediately instead of at the pre-commit hook.
set -uo pipefail

APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$APP_ROOT" || exit 0

input="$(cat)"
file_path="$(echo "$input" | jq -r '.tool_input.file_path // empty')"

[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

case "$file_path" in
  *.rb|*.rake|*.erb|*.yml|*.yaml)
    # Strip trailing whitespace -- matches overcommit's TrailingWhitespace
    # pre-commit hook, which otherwise blocks on lines untouched by the
    # current edit but pre-existing in the same file.
    # NOTE: BSD sed (macOS) does not expand \t inside a bracket expression --
    # it reads literal backslash+t, so `[ \t]` was matching trailing "t"
    # characters and eating the last letter of any line ending in one
    # (e.g. "be_present" -> "be_presen"). [[:blank:]] is the portable fix.
    sed -i '' -E 's/[[:blank:]]+$//' "$file_path" 2>/dev/null
    ;;
esac

case "$file_path" in
  *.rb|*.rake)
    # -a (safe-only), not -A -- rubocop-rails marks some autocorrects
    # SafeAutoCorrect: false (e.g. Rails/StrongParametersExpect rewriting
    # params[:x].permit(...) to params.expect(:x).permit(...), which raises
    # ActionController::ParameterMissing when :x is a Hash, not a scalar --
    # -A applies those anyway, silently changing behavior instead of just
    # style. -a leaves them as reported offenses for a human/Claude to
    # judge, matching the erb_lint tag-count guard below in spirit.
    bundle exec rubocop -a --force-exclusion --no-color --format simple "$file_path" >/dev/null 2>&1
    remaining="$(bundle exec rubocop --force-exclusion --no-color --format simple "$file_path" 2>&1)"
    if ! echo "$remaining" | grep -q "no offenses detected"; then
      echo "RuboCop offenses remain in $file_path after autocorrect:" >&2
      echo "$remaining" >&2
      exit 2
    fi
    ;;
  *.erb)
    # erb_lint -a has been observed mangling multi-line embedded
    # <script> tags (truncated JS strings, deleted closing tags) with
    # no test catching it, since request specs assert on raw response
    # body content, not browser-parsed DOM structure. Guard by
    # comparing open/close HTML tag counts before and after; if
    # autocorrect changed the tag structure, revert it and report
    # instead of silently applying a possibly-corrupting change.
    before_tags="$(grep -oE '</?[a-zA-Z][a-zA-Z0-9]*' "$file_path" | sort | uniq -c)"
    backup="$(mktemp)"
    cp "$file_path" "$backup"
    bundle exec erb_lint "$file_path" -a >/dev/null 2>&1
    after_tags="$(grep -oE '</?[a-zA-Z][a-zA-Z0-9]*' "$file_path" | sort | uniq -c)"
    if [ "$before_tags" != "$after_tags" ]; then
      cp "$backup" "$file_path"
      rm -f "$backup"
      echo "erb_lint autocorrect changed HTML tag structure in $file_path -- reverted, left unformatted. Review and fix manually." >&2
      exit 2
    fi
    rm -f "$backup"
    remaining="$(bundle exec erb_lint "$file_path" 2>&1)"
    if ! echo "$remaining" | grep -q "No errors were found in ERB files"; then
      echo "erb_lint offenses remain in $file_path after autocorrect:" >&2
      echo "$remaining" >&2
      exit 2
    fi
    ;;
esac

exit 0
