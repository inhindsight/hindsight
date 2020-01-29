defmodule Receive.Init do
  use Initializer,
    name: __MODULE__,
    supervisor: Receive.Receipt.Supervisor

  alias Receive.Receipt

  def on_start(state) do
    Receipt.Store.get_all!()
    |> Enum.each(fn accept ->
      Receipt.Supervisor.start_child({Receipt, accept: accept})
    end)

    {:ok, state}
  end
end
