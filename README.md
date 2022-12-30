# DocsetApi

## **DocsetApi HAS MOVED**

DocsetApi is now being maintained over at https://github.com/hissssst/hexdocs_docset_api/

---

An API that produces docset packages (for https://zealdocs.org & dash.app) from any Elixir app or library with hexdocs documentation. 

## Feed API

1. Start the server with `mix phx.start`
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
defmodule Mix.Tasks.MyApp.GenerateDocsets do
  use Mix.Task

  @usage "mix my_app.generate_docsets PATH"

  @shortdoc "Generate Dash-compatible docsets for the app and dependencies."
  @moduledoc """

  Usage:

    $ #{@usage}
  """

  def run([path | _]) when is_binary(path) do
    Mix.Task.run("docs")
    Mix.Task.run("app.start")

    # generate a docset for this codebase
    DocsetApi.Builder.build("MyApp", "docs/exdoc", path)

    # generate docsets for every dependency
    configured_deps = Enum.map(MoodleNet.Mixfile.deps(), &dep_process(&1, path))

  end

  defp dep_process(dep, path) do
    lib = elem(dep, 0)

    DocsetApi.Builder.build(Atom.to_string(lib), path)

  end

  def run(_args),
    do:
      Mix.shell().error("""
      Invalid parameters.

      Usage:

        #{@usage}
      """)
end
```

Then run the task `mix moodle_net.generate_docsets /home/myuser/.local/share/Zeal/Zeal/docsets/` with your desired output directory. 

Voila!

![Screenshot](https://i.imgur.com/hBfzXoO.png)
