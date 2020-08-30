use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :docset_api, DocsetApi.Endpoint,
  http: [port: 80],
  debug_errors: true,
  code_reloader: false,
  check_origin: false,
  watchers: []

# Watch static and templates for browser reloading.
config :docset_api, DocsetApi.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/(?!docsets).*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
