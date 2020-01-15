defmodule Test.StartLink do
  @callback start_link(keyword) :: GenServer.on_start()
end
