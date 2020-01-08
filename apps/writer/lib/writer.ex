defmodule Writer do
  @callback start_link(term) :: GenServer.on_start()
  @callback child_spec(term) :: Supervisor.child_spec()
  @callback write(GenServer.server(), [term]) :: :ok | {:error, term}
  @callback write(GenServer.server(), [term], keyword) :: :ok | {:error, term}
  @callback write([term]) :: :ok | {:error, term}

  @optional_callbacks write: 1
end
