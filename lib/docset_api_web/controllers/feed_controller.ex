defmodule DocsetApi.FeedController do
  use DocsetApi.Web, :controller
  alias DocsetApi.BuilderServer

  def show(conn, %{"package_name" => package}) do
    package = String.trim_trailing(package, ".tgz")

    path =
      Path.absname(
        Path.join([
          DocsetApi.docset_dir(),
          "static",
          "docsets",
          "#{package}.tgz"
        ])
      )

    release = BuilderServer.fetch_package(package, path)

    render(conn, "show.xml", release: release)
  end

  def docset(conn, %{"docset" => docset}) do
    filename =
      Path.absname(
        Path.join([
          DocsetApi.docset_dir(),
          "static",
          "docsets",
          docset
        ])
      )

    if File.exists?(filename) do
      send_file(conn, 200, filename)
    else
      send_resp(conn, 404, "Docset not found")
    end
  end
end
