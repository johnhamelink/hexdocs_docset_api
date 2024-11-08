defmodule DocsetApi.BuilderServer do
  use GenServer

  require Logger
  alias DocsetApi.Builder

  @timeout 50_000

  ## External API

  def start_link(_opts) do
    Logger.info("Starting BuilderServer")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  defp call(message) do
    GenServer.call(__MODULE__, message, @timeout)
  end

  def update_package(pkg, destination) do
    call({:build_package, pkg, destination})
  end

  def fetch_package(pkg) do
    with {:ok, package = %{working_dir: working_dir, release: %{name: name, version: version}}} <-
           call({:get_cached, pkg}),
         package_path <- Path.join([working_dir, "#{name}-#{version}.tgz"]),
         true <- File.exists?(package_path) do
      package
    else
      _cache_miss_state -> call({:build_package, pkg})
    end
  end

  ## Internal API

  def init(init) when is_map(init) do
    Process.send_after(self(), :update_packages, tomorrow())
    {:ok, init}
  end

  defp tomorrow do
    :timer.hours(24)
  end

  def handle_call({:build_package, pkg_name}, _from, packages) do
    with {:ok, docset} <- Builder.build(pkg_name),
         pkg <- Builder.build_tarball(docset, docset[:working_dir]) do
      {:reply, pkg, Map.put(packages, pkg_name, pkg)}
    else
      {:error, docset, :hexpm_not_found} = err ->
        Logger.error """
        Could not build package "#{docset}":
        Hexdocs.pm returned 404 for this libary. Is it spelt
        correctly?
        """
        {:reply, err, packages}
      {:error, docset, unknown} ->
        raise "[#{docset}] An unknown error occurred: #{inspect unknown}"
      wtf ->
        raise "Failed to recognise response from builder: #{inspect wtf}"
    end
  end

  def handle_call({:get_cached, pkg}, _from, packages) do
    {:reply, Map.fetch(packages, pkg), packages}
  end

  def handle_info(:update_packages, packages) do
    packages
    |> Task.async_stream(fn {pkg, _release} -> Builder.build(pkg) end)
    |> Stream.run()

    Process.send_after(self(), :update_packages, tomorrow())
    {:noreply, packages}
  end
end
