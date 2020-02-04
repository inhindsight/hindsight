defmodule Receive.Socket do
  @callback start_link(writer :: function, config :: term) :: GenServer.on_start()
  @callback handle_message(message :: term, state) :: {:noreply, state} when state: term
end
