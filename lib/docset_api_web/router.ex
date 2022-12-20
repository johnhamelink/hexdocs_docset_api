defmodule DocsetApi.Router do
  use DocsetApi.Web, :router

  pipeline :api do
    plug :accepts, ["xml"]
  end

  scope "/feeds", DocsetApi do
    pipe_through :api
    get "/:package_name", FeedController, :show
  end

  scope "/docsets/", DocsetApi do
    pipe_through :api
    get "/:package_name", FeedController, :show
  end
end
