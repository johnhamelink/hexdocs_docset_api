defmodule DocsetApi.Builder do
  require Logger
  alias DocsetApi.FileParser
  alias DocsetApi.Release

  def build(name, destination) do
    state =
      retrieve_release(name, destination)
      |> prepare_environment(name)
      |> download_and_extract_docs
      |> build_plist
      |> build_index
      |> build_tarball(destination)

    Map.fetch!(state, :release)
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
    |> Poison.decode!(as: %{"releases" => [%DocsetApi.Release{}]})
    # |> IO.inspect()
    |> Map.fetch!("releases")
    |> List.first()
    |> Map.fetch!(:url)
    |> HTTPoison.get!()
    |> Map.fetch!(:body)
    |> Poison.decode!(as: %DocsetApi.Release{})
    |> Map.put(:name, name)
    |> Map.put(:destination, destination)
    |> IO.inspect()
  end

  defp prepare_environment(release, name) do
    working_dir = "#{Path.dirname(release.destination)}"
    base_dir = "#{working_dir}/#{name}.docset"
    files_dir = "#{base_dir}/Contents/Resources/Documents"
    docs_archive = "#{working_dir}/#{name}_hexdocs.tar.gz"

    Logger.debug("Create working dir #{release.name}.docset")
    :ok = File.mkdir_p(working_dir)
    {:ok, _} = File.rm_rf(base_dir)
    {:ok, _} = File.rm_rf(docs_archive)
    :ok = File.mkdir_p(base_dir)
    :ok = File.mkdir_p(files_dir)

    IO.inspect(%{
      working_dir: working_dir,
      base_dir: base_dir,
      files_dir: files_dir,
      docs_archive: docs_archive,
      release: release
    })
  end

  defp download_and_extract_docs(
         state = %{
           docs_archive: docs_archive,
           working_dir: working_dir,
           release: release,
           files_dir: files_dir
         }
       ) do
    url =
      release.docs_url ||
        "https://hex.pm/api/packages/#{release.name}/releases/#{release.version}/docs"

    Logger.debug("download from #{url} to #{docs_archive} and extract to #{files_dir}")

    %HTTPoison.Response{body: doc} = HTTPoison.get!(url, [], follow_redirect: true)

    File.write!(docs_archive, doc)

    :erl_tar.extract(
      docs_archive,
      [:compressed, {:cwd, files_dir}]
    )

    state
  end

  defp build_plist(state = %{base_dir: base_dir, release: release}) do
    info_plist = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    <key>CFBundleIdentifier</key>
    <string>#{release.name |> String.downcase()}</string>

    <key>CFBundleName</key>
    <string>#{release.name}</string>

    <key>DocSetPlatformFamily</key>
    <string>elixir</string>

    <key>isDashDocset</key>
    <true/>
    </dict>
    </plist>
    """

    File.write!("#{base_dir}/Contents/Info.plist", info_plist)

    info_meta = """
    {
    "extra": {
      "isJavaScriptEnabled": true
    },
    "name": "#{release.name}",
    "version": "#{release.version}",
    "title": "#{release.name}"
    }
    """

    File.write!("#{base_dir}/meta.json", info_meta)

    state
  end

  def build_index(state = %{base_dir: base_dir, files_dir: files_dir}) do
    index_file = "#{base_dir}/Contents/Resources/docSet.dsidx"

    Sqlitex.with_db(String.to_charlist(index_file), fn db ->
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
      Sqlitex.query(
        db,
        "CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path)"
      )

      # Create a callback which inserts the record into the DB
      index_fn = fn name, type, path ->
        {:ok, _} =
          Sqlitex.query(
            db,
            "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('#{name}', '#{type}', '#{
              path
            }');"
          )
      end

      # Deep-search for files
      files = FileExt.ls_r(files_dir)

      # For each file, parse it for the right keywords and run the callback
      # against the result.
      Enum.each(
        files,
        &FileParser.parse_file(&1, files_dir, index_fn)
      )
    end)

    state
  end

  defp build_tarball(
         state = %{working_dir: working_dir, base_dir: base_dir, release: release},
         destination
       ) do
    file_list =
      FileExt.ls_r(base_dir)
      |> Enum.map(fn file ->
        file
        |> Path.relative_to(working_dir)
        |> String.to_charlist()
      end)

    Logger.debug("cd to #{working_dir}")
    :ok = File.cd(working_dir)

    Logger.debug("Writing tarball to #{destination}")

    # IO.inspect(file_list)

    destination
    |> String.to_charlist()
    |> :erl_tar.create(file_list, [:compressed, :verbose])

    state
  end

  def return_error(%HTTPoison.Error{reason: reason}) do
    IO.inspect(reason)
  end
end
