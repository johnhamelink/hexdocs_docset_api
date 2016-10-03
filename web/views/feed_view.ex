defmodule DocsetApi.FeedView do
  use DocsetApi.Web, :view

  def base_url do
    Application.get_env(:docset_api, :base_url)
  end
end
