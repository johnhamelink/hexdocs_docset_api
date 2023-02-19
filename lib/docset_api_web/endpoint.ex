defmodule DocsetApi.Endpoint do
  use Phoenix.Endpoint, otp_app: :docset_api

  plug Plug.Logger, log: :info

  plug Plug.Parsers,
    parsers: [:urlencoded],
    pass: ["*/*"]

  plug DocsetApi.Router
end
