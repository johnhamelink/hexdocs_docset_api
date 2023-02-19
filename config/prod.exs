import Config

config :docset_api, DocsetApi.Endpoint, server: true

# Do not print debug messages in production
config :logger, level: :info

config :docset_api, DocsetApi.Endpoint, secret_key_base: System.get_env("SECRET_KET_BASE")

config :docset_api,
  base_url: System.get_env("BASE_URL")
