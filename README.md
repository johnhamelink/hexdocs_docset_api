# DocsetApi

## **DocsetApi HAS MOVED**

DocsetApi is now being maintained over at https://github.com/hissssst/hexdocs_docset_api/

---

An API that produces docset packages (for https://zealdocs.org & dash.app) from any Elixir app or library with hexdocs documentation. 

## Feed API

1. Start the server with `PORT=8080 mix phx.server` (or whatever port is available on your machine)
2. In Zeal, go to tools -> docsets -> Installed -> Add Feed
3. Insert the url in the format, `http://localhost:8080/feeds/<package_name>`

Done!

## CLI

You can generate a docset for a library which will be pulled from hex.pm/hexdocs:

`iex> DocsetApi.Builder.build("phoenix", "priv/static/docsets")`

Or you can go further and generate docsets for your own Elixir application + all of its dependencies at once. 

Add DocsetApi as a dependecy in `mix.exs`:

`{:docset_api, only: :dev, runtime: false, git: "https://github.com/mayel/hexdocs_docset_api.git"}`

Put a mix task like this one in your app:

```elixir
defmodule Mix.Tasks.Hello.GenerateDocsets do
  use Mix.Task

  @usage "mix hello.generate_docsets PATH"

  @shortdoc "Generate Dash-compatible docsets for the app and dependencies."
  @moduledoc """

  Usage:

    $ #{@usage}
  """

  def run([path | _]) when is_binary(path) do
    Mix.Task.run("docs")
    Mix.Task.run("app.start")

    # generate a docset for this codebase
    DocsetApi.Builder.build("Hello", "doc")

    # generate docsets for every dependency
    results =
    Hello.MixProject.project[:deps]
    |> IO.inspect(label: "Deps found for our package")
    |> Enum.map(&dep_process(&1, path))

    Mix.shell().info """
    Conversion completed. Here are the results:

    """

    
    Enum.map(results, fn
      %{release: %{name: name, version: version}} ->
        Mix.shell().info " -> OK: #{name} @ #{version}"
      {:error, name, message} ->
        Mix.shell().error """

         -> Could not build docset for #{name}:
            #{message}

        """
      unknown ->
        Mix.shell().error """

         -> Unknown error:
            #{inspect unknown}

        """
    end)
  end

  def run(_args),
    do:
      Mix.shell().error("""
      Invalid parameters.

      Usage:

      #{@usage}
      """)

  defp dep_process(dep, path) do
    lib = elem(dep, 0)

    case entry = DocsetApi.Builder.build(Atom.to_string(lib)) do
      {:error, _pkg, _reason} -> entry
      %{base_dir: _ } -> DocsetApi.Builder.copy_docset(entry, Path.expand(path))
    end
  end
end
```

Then run the task `mix hello.generate_docsets /home/myuser/.local/share/Zeal/Zeal/docsets/` with your desired output directory. 

Voila!

![Screenshot](https://i.imgur.com/hBfzXoO.png)
