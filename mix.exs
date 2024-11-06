defmodule DocsetApi.Mixfile do
  use Mix.Project

  def project do
    [
      app: :docset_api,
      version: File.read!("VERSION"),
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
      {:phoenix, "~> 1.6"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_view, "~> 2.0"},
      {:plug_cowboy, "~> 2.7"},
      {:httpoison, "~> 2.2"},
      {:poison, "~> 2.2 or ~> 3.0 or ~> 4.0 or ~> 5.0 or ~> 6.0"},
      {:exqlite, "~> 0.27"},
      {:floki, ">= 0.3.0"},
      {:ex_doc, "~> 0.29.1"}
    ]
  end
end
