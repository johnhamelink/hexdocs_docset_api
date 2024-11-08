defmodule DocsetApi.FeedController do
  use DocsetApi.Web, :controller
  alias DocsetApi.BuilderServer

  def show(conn, %{"package_name" => package}) do
    with entry when is_map(entry) <- BuilderServer.fetch_package(package) do
      render(conn, "show.xml", entry: entry)
    else
      {:error, _docset, :hexpm_not_found} ->
        send_resp(conn, 404, "<error>Docset not found</error>")
    end
  end

  def docset(conn, %{"docset" => docset}) do

    package = String.trim_trailing(docset, ".tgz")
    [name, _] = String.split(package, "-")

    filename =
      Path.join([System.tmp_dir(), "hexdocs_docset", name, docset])
      |> Path.absname()
      |> IO.inspect(label: "candidate filename")

    if File.exists?(filename) do
      send_file(conn, 200, filename)
    else
      send_resp(conn, 404, "Docset not found")
    end
  end
end
