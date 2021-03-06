defmodule Broadcast.Cache.Registry do
  @moduledoc """
  `Registry` implementation for managing channel caches.
  """
  def child_spec(_init_arg) do
    Supervisor.child_spec({Registry, keys: :unique, name: __MODULE__}, [])
  end

  @spec via(key) :: {:via, Registry, {__MODULE__, key}} when key: term
  def via(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  @spec registered_processes() :: list
  def registered_processes() do
    Registry.select(__MODULE__, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  @spec whereis(key :: term) :: pid | :undefined
  def whereis(key) do
    case Registry.lookup(__MODULE__, key) do
      [{pid, _}] -> pid
      _ -> :undefined
    end
  end
end
