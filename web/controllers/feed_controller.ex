defmodule DocsetApi.FeedController do
  use DocsetApi.Web, :controller
  alias DocsetApi.BuilderServer

  def show(conn, %{"package_name" => package}) do
    release =
      BuilderServer.fetch_package(
        package,
        Path.absname("priv/static/docsets/#{package}.tgz"))

    render conn, "show.xml", release: release
  end

end
