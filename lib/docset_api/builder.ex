defmodule DocsetApi.Builder do
  require Logger
  alias DocsetApi.FileParser
  alias DocsetApi.Release

  @doc """
  Build a docset from a hex library name
  """
  def build(name) do
    with {:ok, release} <- retrieve_release(name),
         {:ok, state} <- prepare_environment(name, release),
         {:ok, state} <- download_and_extract_docs(state),
         {:ok, state} <- build_plist(state),
         {:ok, state} <- copy_logo(state),
         {:ok, state} <- build_index(state) do
      state
    else
      {:error, msg} -> {:error, name, msg}
    end
  end

  @doc """
  Build a docset from a folder
  """
  def build(name, from_path) do
    state = %Release{
      name: name
    }

    with {:ok, state} <- prepare_environment(name, state, from_path),
         {:ok, state} <- copy_docs(state),
         {:ok, state} <- build_plist(state),
         {:ok, state} <- build_index(state) do
      state
    end
  end

  def build_tarball(
        %{base_dir: base_dir, release: %{name: name, version: version}} = state,
        dest_dir
      ) do
    filename = Path.join(dest_dir, "#{name}-#{version}.tgz")
    Logger.debug("Writing tarball to #{filename}")
    System.cmd("tar", ["-czvf", filename, "."], cd: base_dir)

    state
  end

  def copy_docset(%{base_dir: base_dir} = state, dest_dir) do
    Logger.debug("Copying #{base_dir} to #{dest_dir}")

    {:ok, _} =
      File.cp_r(
        base_dir,
        Path.join([dest_dir, Path.basename(base_dir)])
      )

    state
  end

  defp return_error(%HTTPoison.Error{reason: reason}) do
    Logger.error(inspect(reason, pretty: true))
  end

  defp retrieve_release(name) do
    "https://hex.pm/api/packages/#{name}"
    |> HTTPoison.get()
    |> case do
      {:ok, response} -> get_latest_version(name, response)
      {:error, err} -> return_error(err)
    end
  end

  defp get_latest_version(name, %HTTPoison.Response{body: json, status_code: 200}) do
    release =
      json
      |> Poison.decode!(as: %{"releases" => [%Release{}]})
      |> Map.fetch!("releases")
      |> List.first()
      |> Map.fetch!(:url)
      |> HTTPoison.get!()
      |> Map.fetch!(:body)
      |> Poison.decode!(as: %Release{})
      |> Map.replace!(:name, name)

    {:ok, release}
  end

  defp get_latest_version(name, %HTTPoison.Response{body: json, status_code: status})
       when status != 200 do
    Logger.warning(~s"""
    Could not process response from hex.pm for #{name} dependency:

    Received #{status} from server. Skipping.
    Message from server:

    #{inspect(Poison.decode!(json))}
    """)

    case status do
      404 -> {:error, :hexpm_not_found}
    end
  end

  defp prepare_environment(name, %Release{} = release, from_path \\ nil) do
    working_dir =
      Path.join([System.tmp_dir(), "hexdocs_docset", name])
      |> Path.expand()

    base_dir =
      Path.join([working_dir, "#{name}.docset"])
      |> Path.expand()

    files_dir =
      Path.join([base_dir, "Contents", "Resources", "Documents"])
      |> Path.expand()

    docs_archive =
      Path.join([working_dir, "#{name}_hexdocs.tar.gz"])
      |> Path.expand()

    Logger.debug("Create working dir #{base_dir}")

    File.mkdir_p!(working_dir)
    File.rm_rf!(base_dir)
    File.rm_rf!(docs_archive)
    File.mkdir_p!(base_dir)
    File.mkdir_p!(files_dir)

    {:ok,
     %{
       working_dir: working_dir,
       base_dir: base_dir,
       files_dir: files_dir,
       docs_archive: docs_archive,
       from_path: from_path,
       release: release
     }}
  end

  defp download_and_extract_docs(
         %{
           docs_archive: docs_archive,
           release: %Release{name: name, version: version, docs_url: docs_url},
           files_dir: files_dir
         } = state
       ) do
    url = docs_url || "https://hex.pm/api/packages/#{name}/releases/#{version}/docs"

    Logger.debug("download from #{url} to #{docs_archive} and extract to #{files_dir}")

    %HTTPoison.Response{body: doc} = HTTPoison.get!(url, [], follow_redirect: true)

    File.write!(docs_archive, doc)

    :erl_tar.extract(docs_archive, [:compressed, cwd: files_dir])

    {:ok, state}
  end

  defp copy_docs(%{from_path: from_path, files_dir: files_dir} = state) do
    Logger.debug("copy from #{from_path} to #{files_dir}")
    File.cp_r(from_path, files_dir)
    state
  end

  defp build_plist(%{base_dir: base_dir, release: %Release{name: name, version: version}} = state) do
    info_plist = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>CFBundleIdentifier</key>
        <string>#{String.downcase(name)}</string>

        <key>CFBundleName</key>
        <string>#{name}</string>

        <key>DocSetPlatformFamily</key>
        <string>elixir</string>

        <key>isJavaScriptEnabled</key>
        <true/>

        <key>isDashDocset</key>
        <true/>

        <key>DashDocSetPluginKeyword</key>
        <string>#{name}</string>
      </dict>
    </plist>
    """

    base_dir
    |> Path.join("Contents/Info.plist")
    |> File.write!(info_plist)

    info_meta =
      Poison.encode!(%{
        extra: %{isJavaScriptEnabled: true},
        name: name,
        version: version,
        title: name
      })

    base_dir
    |> Path.join("meta.json")
    |> File.write!(info_meta)

    {:ok, state}
  end

  defp copy_logo(%{base_dir: base_dir, files_dir: files_dir} = state) do
    files_dir
    |> find_logo()
    |> File.cp(Path.join(base_dir, "icon.png"))

    {:ok, state}
  end

  defp find_logo(files_dir) do
    package_logo_file = Path.join([files_dir, "assets", "logo.png"])

    if File.exists?(package_logo_file) do
      package_logo_file
    else
      Path.join([to_string(:code.priv_dir(:docset_api)), "static", "images", "hexpm.png"])
    end
  end

  defp build_index(%{base_dir: base_dir, files_dir: files_dir} = state) do
    sqlite_file =
      [base_dir, "Contents", "Resources", "docSet.dsidx"]
      |> Path.join()
      |> String.to_charlist()

    {:ok, db} = Exqlite.Basic.open(sqlite_file)

    # Create SQLite index table
    {:ok, _query, _result, db} =
      Exqlite.Basic.exec(db, """
        CREATE TABLE searchIndex(
          id INTEGER PRIMARY KEY,
          name TEXT,
          type TEXT,
          path TEXT
          );
      """)

    # Add a unique index for the name, type and path combo
    {:ok, _query, _result, db} =
      Exqlite.Basic.exec(db, "CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path)")

    # Deep-search for files
    files = ls_r(files_dir)
    html_files = Enum.filter(files, &String.match?(&1, ~r"\.html"))

    for file <- html_files do
      Logger.debug("Parsing #{file} ...")

      html = Floki.parse_document!(File.read!(file))
      relative_path = Path.relative_to(file, files_dir)

      # Set `sidebar-closed` on the body instead of `sidebar-opened`.
      # Remove sidebar-button sidebar-toggle
      # Remove icon-action display-settings
      content =
        FileParser.parse(html, relative_path, fn name, type, path ->
          query =
            "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('#{name}', '#{type}', '#{path}');"

          {:ok, _query, _result, _db} = Exqlite.Basic.exec(db, query)
        end)
        |> Floki.attr("body", "class", fn
          nil ->
            "sidebar-closed"

          classes ->
            if String.contains?(classes, "sidebar-opened") do
              String.replace(classes, "sidebar-opened", "sidebar-closed")
            else
              "#{classes} sidebar-closed"
            end
        end)
        |> Floki.find_and_update("button", fn button ->
          button_classes = Floki.attribute(button, "class")

          if Enum.all?(button_classes, &String.starts_with?(&1, "sidebar-")) or
               Enum.member?(button_classes, "display-settings") do
            :delete
          else
            button
          end
        end)
        |> Floki.raw_html()

      File.write(
        file,
        content
      )
    end

    skipped_files = Enum.reject(files, &Enum.member?(html_files, &1))

    Logger.debug("""
    Skipped the following files:

    #{Enum.each(skipped_files, &" - #{&1}")}
    """)

    :ok = Exqlite.Basic.close(db)

    {:ok, state}
  end

  defp ls_r(path) do
    cond do
      File.regular?(path) ->
        [path]

      File.dir?(path) ->
        path
        |> File.ls!()
        |> Enum.flat_map(&ls_r(Path.join(path, &1)))

      true ->
        []
    end
  end
end
