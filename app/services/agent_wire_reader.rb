# frozen_string_literal: true

# Reads zdots-ctx bus history for the "Agent Wire" dashboard tab -- shells
# out to the CLI rather than connecting to zdots' own Postgres DB directly,
# so this stays a read via the same sanctioned interface any other tool
# uses, not a new cross-service DB coupling for a read-only display.
#
# Plain `bus-read` (no --unread) returns full channel history without
# touching any read cursor -- --unread is the only flag that advances
# state, so this is safe to call on every dashboard load.
class AgentWireReader
  ZDOTS_CTX = "/Users/mike/.config/zsh/bin/zdots-ctx"
  PARTICIPANT = "agent-wwworkremote"
  CHANNELS = %w[job-leads general].freeze

  # The launchd-run web service's PATH is macOS's bare default
  # (/usr/bin:/bin:/usr/sbin:/sbin) -- no mise shims, no Homebrew -- so
  # zdots-ctx (which shells out to ruby/psql internally) fails silently
  # under Puma even though it works fine from an interactive shell.
  # Fixed here, in our own subprocess call, not in zdots-ctx.
  SUBPROCESS_PATH = "/Users/mike/.local/share/mise/shims:/opt/homebrew/bin:/opt/homebrew/sbin:" \
                    "/usr/bin:/bin:/usr/sbin:/sbin"

  # Hard timeout, not just a fast-fail preference: this subprocess has been
  # observed to hang rather than error (macOS Keychain access confirmation
  # has no UI to answer in this headless context), and it runs on every
  # dashboard load -- it must never be able to hang the request. ponytail:
  # doesn't force-kill an orphaned child on timeout, add if it recurs.
  READ_TIMEOUT = 3

  MESSAGE_START = /^\[(\d{2}:\d{2})\] (\S+) \([0-9a-f]+\): /

  Message = Struct.new(:time, :participant, :body, keyword_init: true)

  def self.call = new.call

  def call
    CHANNELS.index_with { |channel| read(channel) }
  end

  private

  # Bundler env vars (BUNDLE_GEMFILE et al.) also leak into child processes
  # by default -- without unsetting them, zdots-ctx tries to load this
  # app's Gemfile instead of its own and fails on a missing gem.
  def read(channel)
    output = Bundler.with_unbundled_env { popen_bus_read(channel) }
    parse(output).reverse
  end

  def popen_bus_read(channel)
    Timeout.timeout(READ_TIMEOUT) { bus_read_output(channel) }
  rescue Timeout::Error, Errno::ENOENT, IOError
    ""
  end

  def bus_read_output(channel)
    IO.popen({ "PATH" => SUBPROCESS_PATH }, [ZDOTS_CTX, "bus-read", channel, "--as", PARTICIPANT], err: File::NULL,
             &:read)
  end

  def parse(output)
    parts = output.split(MESSAGE_START)
    parts.shift
    parts.each_slice(3).map { |time, participant, body|
      Message.new(time: time, participant: participant, body: body.strip)
    }
  end
end
