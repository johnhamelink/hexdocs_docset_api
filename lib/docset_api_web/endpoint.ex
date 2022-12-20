defmodule DocsetApi.Endpoint do
  use Phoenix.Endpoint, otp_app: :docset_api

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :docset_api, gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  docset_dir = DocsetApi.docset_dir()

  plug Plug.Static,
    at: "/", gzip: false, from: Path.join(docset_dir, "static"),
    only: [ "docsets" ]

  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug DocsetApi.Router
end
