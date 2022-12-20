defmodule DocsetApi.FeedController do
  use DocsetApi.Web, :controller
  alias DocsetApi.BuilderServer
  def show(conn, %{"package_name" => package}) do
    package = String.trim_trailing(package, ".tgz")


    path =
      Path.absname Path.join [
        DocsetApi.docset_dir(),
        "static",
        "docsets",
        "#{package}.tgz",
      ]

    release = BuilderServer.fetch_package(package, path)

    render conn, "show.xml", release: release
  end

end
