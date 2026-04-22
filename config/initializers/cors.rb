# frozen_string_literal: true

# CORS for the Chrome extension ingestion assistant.
#
# Chrome content scripts with host_permissions for the target origin bypass
# CORS by default, so this may not be strictly required. It is activated as a
# safety net — if the browser enforces CORS for a given Chrome version or flag,
# requests from the extension to /api/* will still succeed.
#
# The extension's Origin header is "chrome-extension://<id>", where <id> varies
# per installation and cannot be predicted. We allow the pattern broadly for the
# /api/ namespace only and do not use credentials=true (Basic Auth is sent as a
# header, not a cookie, so allow_credentials is not needed).

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      /\Achrome-extension:\/\//,  # any installed Chrome extension
      'http://localhost:3010',    # local development fetch (e.g. from the app itself)
      'http://127.0.0.1:3010'
    )

    resource '/api/*',
      headers: :any,
      methods: %i[get post options],
      credentials: false,
      max_age: 300
  end
end
