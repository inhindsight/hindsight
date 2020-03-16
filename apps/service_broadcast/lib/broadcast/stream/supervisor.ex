defmodule Broadcast.Stream.Supervisor do
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_child(Supervisor.child_spec() | {module, arg :: term}) ::
          DynamicSupervisor.on_start_child()
  def start_child(child_spec) do
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @spec terminate_child(pid) :: :ok | {:error, :not_found}
  def terminate_child(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  @spec kill_all_children() :: :ok
  def kill_all_children() do
    child_pids =
      DynamicSupervisor.which_children(__MODULE__)
      |> Enum.map(fn {_, pid, _, _} -> pid end)

    refs = Enum.map(child_pids, &Process.monitor/1)

    Enum.each(child_pids, &terminate_child/1)

    Enum.each(refs, fn ref ->
      receive do
        {:DOWN, ^ref, _, _, _} -> :ok
      after
        1_000 ->
          raise "Unable to verify death of child: #{inspect(Process.info(self(), :messages))}"
      end
    end)
  end
end
