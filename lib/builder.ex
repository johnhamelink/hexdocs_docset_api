defmodule DocsetApi.Builder do
  require Logger
  alias DocsetApi.FileParser

  @tmp_dir "/tmp/docsets"

  def build(name) do
    retrieve_release(name)
    |> prepare_environment
    |> download_and_extract_docs
    |> build_plist
    |> build_index
    |> build_tarball
  end

  defp prepare_environment(release) do
    # 1. Create working dir "#{release.name}.docset"
    working_dir = "#{@tmp_dir}/#{release.name}"
    base_dir    = "#{working_dir}.docset"
    files_dir   = "#{base_dir}/Contents/Resources/Documents"
    :ok = File.mkdir_p(files_dir)
    :ok = File.mkdir_p(working_dir)

    %{
      working_dir: working_dir,
      base_dir: base_dir,
      files_dir: files_dir,
      release: release
    }
  end

  defp download_and_extract_docs(state = %{working_dir: working_dir, release: release, files_dir: files_dir}) do
    docs_archive = "#{working_dir}/hexdocs.tar.gz"
    %HTTPoison.Response{body: doc} = HTTPoison.get!(release.docs_url)
    File.write!(docs_archive, doc)
    :erl_tar.extract(
      docs_archive,
      [:compressed, {:cwd, files_dir}]
    )

    state
  end

  defp build_plist(state = %{base_dir: base_dir}) do
    info_plist = ~S"""
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>CFBundleIdentifier</key>
        <string>#{release.identifier |> String.downcase}</string>

        <key>CFBundleName</key>
        <string>#{release.name}</string>

        <key>DocSetPlatformFamily</key>
        <string>#{release.platform_family}</string>

        <key>isDashDocset</key>
        <true/>
      </dict>
    </plist>
    """
    File.write!("#{base_dir}/Contents/Info.plist", info_plist)

    state
  end

  def build_index(state = %{base_dir: base_dir, files_dir: files_dir}) do
    index_file = "#{base_dir}/Contents/Resources/docSet.dsidx"
    Sqlitex.with_db(String.to_charlist(index_file), fn(db) ->
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
      Sqlitex.query(db,
        "CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path)")


      # Create a callback which inserts the record into the DB
      index_fn = fn(name, type, path) ->
        Logger.debug "Inserting #{type} index for #{name}"
        {:ok, _} = Sqlitex.query(db,
          "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('#{name}', '#{type}', '#{path}');"
        )
      end

      # Deep-search for files
      files = FileExt.ls_r(files_dir)

      # For each file, parse it for the right keywords and run the callback
      # against the result.
      Enum.each(files,
        &(FileParser.parse_file(&1, files_dir, index_fn)))

    end)

    state
  end

  defp build_tarball(%{base_dir: base_dir, release: release, working_dir: working_dir}) do
    file_list =
      FileExt.ls_r(base_dir)
      |> Enum.map(fn(file) ->
        file
        |> Path.relative_to(@tmp_dir)
        |> String.to_charlist
      end)

    :ok = File.cd(@tmp_dir)

    outfile = "#{working_dir}/#{release.name}.tgz"

    outfile
    |> String.to_charlist
    |> :erl_tar.create(file_list, [:compressed])

    outfile
  end


  def retrieve_release(name) do
    "https://hex.pm/api/packages/#{name}"
    |> HTTPoison.get
    |> case do
      {:ok, response} -> get_latest_version(name, response)
      {:error, err}   -> return_error(err)
    end
  end

  def get_latest_version(name, %HTTPoison.Response{body: json}) do
    json
    |> Poison.decode!(as: %{"releases" => [%DocsetApi.Release{}]})
    |> Map.fetch!("releases")
    |> List.first
    |> Map.fetch!(:url)
    |> HTTPoison.get!
    |> Map.fetch!(:body)
    |> Poison.decode!(as: %DocsetApi.Release{})
    |> Map.put(:name, name)
  end

  def return_error(%HTTPoison.Error{reason: reason}) do
    IO.inspect(reason)
  end

end
