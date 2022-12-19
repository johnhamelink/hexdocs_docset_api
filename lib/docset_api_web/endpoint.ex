defmodule DocsetApi.Endpoint do
  use Phoenix.Endpoint, otp_app: :docset_api

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :docset_api, gzip: false,
    only: ~w(docsets css fonts images js favicon.ico robots.txt)

  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug DocsetApi.Router
end
