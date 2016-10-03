defmodule DocsetApi.PageController do
  use DocsetApi.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
