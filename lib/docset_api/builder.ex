defmodule DocsetApi.Builder do
  require Logger
  alias DocsetApi.FileParser
  alias DocsetApi.Release

  @doc """
  Build a docset from a hex library name
  """
  def build(name, destination) do
    name
    |> retrieve_release(destination)
    |> prepare_environment(name)
    |> download_and_extract_docs()
    |> build_plist()
    |> copy_logo()
    |> build_index()
    |> build_tarball(destination)
    |> Map.fetch!(:release)
  end

  @doc """
  Build a docset from a folder
  """
  def build(name, from_path, destination) do
    %Release{
      name: name,
      destination: destination
    }
    |> prepare_environment(name, from_path)
    |> copy_docs()
    |> build_plist()
    |> build_index()
    |> build_tarball(destination)
    |> Map.fetch!(:release)
  end

  def retrieve_release(name, destination) do
    "https://hex.pm/api/packages/#{name}"
    |> HTTPoison.get()
    |> case do
      {:ok, response} -> get_latest_version(name, destination, response)
      {:error, err} -> return_error(err)
    end
  end

  def get_latest_version(name, destination, %HTTPoison.Response{body: json}) do
    json
    |> Poison.decode!(as: %{"releases" => [%Release{}]})
    |> Map.fetch!("releases")
    |> List.first()
    |> Map.fetch!(:url)
    |> HTTPoison.get!()
    |> Map.fetch!(:body)
    |> Poison.decode!(as: %Release{})
    |> Map.replace!(:name, name)
    |> Map.replace!(:destination, destination)
  end

  defp prepare_environment(
         %Release{name: release_name, destination: dest} = release,
         name,
         from_path \\ nil
       ) do
    working_dir = Path.dirname(dest)
    base_dir = Path.join([working_dir, "#{name}.docset"])
    files_dir = Path.join([base_dir, "Contents", "Resources", "Documents"])
    docs_archive = Path.join([working_dir, "#{name}_hexdocs.tar.gz"])

    Logger.debug("Create working dir #{release_name}.docset")

    File.mkdir_p!(working_dir)
    File.rm_rf!(base_dir)
    File.rm_rf!(docs_archive)
    File.mkdir_p!(base_dir)
    File.mkdir_p!(files_dir)

    %{
      working_dir: working_dir,
      base_dir: base_dir,
      files_dir: files_dir,
      docs_archive: docs_archive,
      from_path: from_path,
      release: release
    }
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
    state
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

    state
  end

  defp copy_logo(%{base_dir: base_dir, files_dir: files_dir} = state) do
    files_dir
    |> find_logo()
    |> File.cp(Path.join(base_dir, "icon.png"))

    state
  end

  defp find_logo(files_dir) do
    package_logo_file = Path.join([files_dir, "assets", "logo.png"])

    if File.exists?(package_logo_file) do
      package_logo_file
    else
      Path.join([to_string(:code.priv_dir(:docset_api)), "static", "images", "hexpm.png"])
    end
  end

  def build_index(%{base_dir: base_dir, files_dir: files_dir} = state) do
    [base_dir, "Contents", "Resources", "docSet.dsidx"]
    |> Path.join()
    |> String.to_charlist()
    |> Sqlitex.with_db(fn db ->
      # Create SQLite index table
      Sqlitex.query(db, """
      CREATE TABLE searchIndex(
        id INTEGER PRIMARY KEY,
        name TEXT,
        type TEXT,
        path TEXT
        );
      """)

      # Add a unique index for the name, type and path combo
      Sqlitex.query(db, "CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path)")

      # Deep-search for files
      files = ls_r(files_dir)

      # For each file, parse it for the right keywords and run the callback # against the result.
      Enum.each(files, fn file ->
        if Path.extname(file) == ".html" do
          # Logger.debug("parse #{file}")

          html = Floki.parse_document!(File.read!(file))
          relative_path = Path.relative_to(file, files_dir)

          # Set sidebar-closed sur le body au lieu de sidebar-opened
          # Remove sidebar-button sidebar-toggle
          # Remove icon-action display-settings
          content =
            FileParser.parse_zeal_navigation(html, relative_path, fn name, type, path ->
              query =
                "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('#{name}', '#{type}', '#{path}');"

              {:ok, _} = Sqlitex.query(db, query)
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
        else
          Logger.debug("skip #{file}")
        end
      end)
    end)

    state
  end

  defp build_tarball(%{base_dir: base_dir} = state, destination) do
    Logger.debug("Writing tarball to #{destination}")
    System.cmd("tar", ["-czvf", destination, "."], cd: base_dir)
    state
  end

  def return_error(%HTTPoison.Error{reason: reason}) do
    Logger.error(inspect(reason, pretty: true))
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
