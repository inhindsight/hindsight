defmodule ReceiveTest do
  use ExUnit.Case
  import Mox
  import Events, only: [accept_start: 0, accept_end: 0]
  import AssertAsync
  require Temp.Env

  @instance Receive.Application.instance()
  @moduletag capture_log: true

  Temp.Env.modify([
    %{
      app: :service_receive,
      key: Receive.SocketManager,
      update: fn config ->
        Keyword.put(config, :writer, Receive.WriterMock)
      end
    }
  ])

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    on_exit(fn ->
      Receive.Acception.Supervisor.kill_all_children()
    end)

    :ok
  end

  setup do
    Brook.Test.clear_view_state(@instance, "acceptions")

    :ok
  end
end
