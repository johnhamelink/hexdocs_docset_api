defmodule DocsetApi.FeedController do
  use DocsetApi.Web, :controller
  alias DocsetApi.BuilderServer

  def show(conn, %{"package_name" => package}) do
    dir = Application.get_env(:docset_api, :docset_dir, "/tmp/hexdocs_docset_api")

    path =
      Path.absname Path.join [
        dir,
        "static/docsets",
        "#{package}.tgz",
      ]

    release = BuilderServer.fetch_package(package, path)

    render conn, "show.xml", release: release
  end

end
