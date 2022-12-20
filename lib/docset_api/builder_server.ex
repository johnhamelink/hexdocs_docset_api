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

  def update_package(pkg, destination),
    do: GenServer.call(__MODULE__, {:build_package, pkg, destination}, @timeout)

  def fetch_package(pkg, destination) do
    case GenServer.call(__MODULE__, {:get_cached, pkg}, @timeout) do
      {:ok, package} ->
        package

      :error ->
        GenServer.call(
          __MODULE__,
          {:build_package, pkg, destination},
          @timeout
        )
    end
  end

  ## Internal API

  def init(init) when is_map(init) do
    Process.send_after(self(), :update_packages, tomorrow())
    {:ok, init}
  end

  defp tomorrow do
    1000 * 60 * 60 * 24
  end

  def handle_call({:build_package, pkg_name, destination}, _from, packages) do
    pkg = Builder.build(pkg_name, destination)
    {:reply, pkg, Map.put(packages, pkg_name, pkg)}
  end

  def handle_call({:get_cached, pkg}, _from, packages) do
    {:reply, Map.fetch(packages, pkg), packages}
  end

  def handle_info(:update_packages, packages) do
    await_timeout_ms = 1000 * 10

    packages
    |> Enum.map(fn {pkg, release} ->
      Task.async(fn ->
        Builder.build(pkg, release.destination)
      end)
    end)
    |> Enum.each(&Task.await(&1, await_timeout_ms))

    Process.send_after(self(), :update_packages, tomorrow())
    {:noreply, packages}
  end
end
