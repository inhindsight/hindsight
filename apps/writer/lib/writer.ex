defmodule Writer do
  @callback start_link(term) :: GenServer.on_start()
  @callback child_spec(term) :: Supervisor.child_spec()
  @callback write(GenServer.server(), [term], keyword) :: :ok | {:error, term}
end
