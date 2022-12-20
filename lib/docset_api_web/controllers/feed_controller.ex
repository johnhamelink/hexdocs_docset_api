defmodule DocsetApi.FeedController do
  use DocsetApi.Web, :controller
  alias DocsetApi.BuilderServer

  def show(conn, %{"package_name" => package}) do
    path = Path.absname("#{:code.priv_dir :docset_api}/static/docsets/#{package}.tgz")
    release = BuilderServer.fetch_package(package, path)

    render conn, "show.xml", release: release
  end

end
