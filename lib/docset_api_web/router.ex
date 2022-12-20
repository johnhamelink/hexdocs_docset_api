defmodule DocsetApi.Router do
  use DocsetApi.Web, :router

  scope "/", DocsetApi do
    get "/feeds/:package_name", FeedController, :show
    get "/docsets/:docset", FeedController, :docset
  end
end
