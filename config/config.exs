# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# Configures the endpoint
config :docset_api, DocsetApi.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "V0huC+gn7HywVxfQwhRi3l7fB1tALe7Eubndpd4ePjgjPw5tYg9Pyhq1L86193zz",
  render_errors: [view: DocsetApi.ErrorView, accepts: ~w(html json xml)],
  pubsub_server: DocsetApi.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Poison

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
