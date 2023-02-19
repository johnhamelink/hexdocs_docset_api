import Config

port = String.to_integer(System.fetch_env!("PORT"))

config :docset_api, DocsetApi.Endpoint,
  http: [port: port],
  url: [host: "localhost", port: port]
