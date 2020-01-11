defmodule Broadcast.Stream.Registry do

  def start_link(_args) do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def child_spec(_args) do
    Supervisor.child_spec(Registry, [])
    |> Map.put(:start, {__MODULE__, :start_link, [[keys: :unique, name: __MODULE__]]})
  end

  def via(name) do
    {:via, Registry, {__MODULE__, name}}
  end

  def registered_processes() do
    Registry.select(__MODULE__, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def whereis(name) do
    case Registry.lookup(__MODULE__, name) do
      [{pid, _}] -> pid
      _ -> nil
    end
  end

end
