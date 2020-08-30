defmodule DocsetApi.BuilderServer do
  use GenServer

  require Logger
  alias DocsetApi.Builder

  @name __MODULE__

  ## External API

  def start_link do
    Logger.info("Starting BuilderServer")
    GenServer.start_link(@name, %{}, name: @name)
  end

  def update_package(pkg, destination),
    do: GenServer.call(@name, {:build_package, pkg, destination}, 50000)

  def fetch_package(pkg, destination) do
    case GenServer.call(@name, {:get_cached, pkg}) do
      {:ok, package} ->
        package

      :error ->
        GenServer.call(
          @name,
          {:build_package, pkg, destination}
        )
    end
  end

  ## Internal API

  def init(init) when is_map(init) do
    Process.send_after(self(), :update_packages, tomorrow)
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

    Process.send_after(self(), :update_packages, tomorrow)
    {:noreply, packages}
  end
end
