defmodule DocsetApi.Router do
  use DocsetApi.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["xml"]
  end

  scope "/", DocsetApi do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/feeds", DocsetApi do
    pipe_through :api
    get "/:package_name", FeedController, :show
  end
end
