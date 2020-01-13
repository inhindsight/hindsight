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
end
