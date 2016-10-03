defmodule DocsetApi.FeedView do
  use DocsetApi.Web, :view

  def base_url do
    Application.get_env(:docset_api, DocsetApi.Endpoint)
    |> get_in([:url, :host])
  end

  def port do
    Application.get_env(:docset_api, DocsetApi.Endpoint)
    |> get_in([:http, :port])
  end

end
