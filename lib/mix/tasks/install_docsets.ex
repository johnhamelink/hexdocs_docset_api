defmodule Mix.Tasks.HexdocsDocset.InstallDocsets do
  use Mix.Task

  @usage "mix hexdocs_docset.install_docsets package_name [version] [output_path]"

  @shortdoc "Generate Dash-compatible docsets"
  @moduledoc """

  Usage:

    $ #{@usage}
  """

  def run([package | _] = args) when is_binary(package) do
    Mix.Task.run("app.start")

    # generate a docset for this codebase
    # TODO: Handle version requirements
    build = DocsetApi.Builder.build(package)

    # Detect if optional flags are present
    copy_to_index = Enum.find_index(args, fn x -> x == "--copy-to" end)
    compress? = Enum.member?(args, "--compress")

    build_ok? = fn ->
      cond do
        is_tuple(build) -> false
        true -> true
      end
    end

    # Wrap this in a function so it's only called at the time that
    # `copy_to` is accessed.
    copy_to = fn ->
      Enum.at(args, copy_to_index + 1)
      |> Path.expand()
    end

    if build_ok? do
      build =
        cond do
          compress? and copy_to_index ->
            DocsetApi.Builder.build_tarball(build, copy_to.())

          copy_to_index ->
            DocsetApi.Builder.copy_docset(build, copy_to.())

          compress? ->
            DocsetApi.Builder.build_tarball(build, File.cwd!())

          true ->
            build
        end

      Mix.shell().info("""
      Conversion completed. Here are the results:

      #{inspect(build, pretty: true)}

      """)
    end
  end

  def run(_args),
    do:
      Mix.shell().error("""
      Invalid parameters.

      Usage:

      #{@usage}
      """)
end
