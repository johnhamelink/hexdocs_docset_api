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

  def fetch_package(pkg, destination) do
    case call {:get_cached, pkg} do
      {:ok, package} -> package
      :error -> call {:build_package, pkg, destination}
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

  def handle_call({:build_package, pkg_name, destination}, _from, packages) do
    pkg = Builder.build(pkg_name, destination)
    {:reply, pkg, Map.put(packages, pkg_name, pkg)}
  end

  def handle_call({:get_cached, pkg}, _from, packages) do
    {:reply, Map.fetch(packages, pkg), packages}
  end

  def handle_info(:update_packages, packages) do
    packages
    |> Task.async_stream(fn {pkg, release} -> Builder.build(pkg, release.destination) end)
    |> Stream.run()

    Process.send_after(self(), :update_packages, tomorrow())
    {:noreply, packages}
  end
end
