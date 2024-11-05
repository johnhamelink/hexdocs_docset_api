defmodule DocsetApi.Mixfile do
  use Mix.Project

  def project do
    [
      app: :docset_api,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {DocsetApi, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]

  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.1"},
      {:plug_cowboy, "~> 2.7"},
      {:httpoison, "~> 2.2"},
      {:poison, "~> 2.2 or ~> 3.0 or ~> 4.0 or ~> 5.0 or ~> 6.0"},
      {:sqlitex, "~> 1.7"},
      {:esqlite, "~> 0.8", override: true},
      {:floki, ">= 0.3.0"}
    ]
  end
end
