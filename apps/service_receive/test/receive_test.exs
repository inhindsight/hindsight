defmodule ReceiveTest do
  use ExUnit.Case
  import Mox
  import Events, only: [accept_start: 0, accept_end: 0]
  require Temp.Env

  @instance Receive.Application.instance()
  @moduletag capture_log: true

  Temp.Env.modify([
    %{
      app: :service_receive,
      key: Receive.SocketManager,
      set: [writer: Receive.WriterMock]
    }
  ])

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    {:ok, source} = SourceSocket.start_link(port: 6789, schedule: true, interval: 500)

    on_exit(fn ->
      Process.exit(source, :kill)
      Receive.Acception.Supervisor.kill_all_children()
    end)

    :ok
  end

  setup do
    Brook.Test.clear_view_state(@instance, "acceptions")
    :ok
  end

  test "receives data from source" do
    test = self()
    {:ok, dummy_writer} = Agent.start_link(fn -> :dummy_writer end)

    Receive.WriterMock
    |> expect(:start_link, fn args ->
      send(test, {:start_link, args})
      {:ok, dummy_writer}
    end)
    |> expect(:write, fn server, messages ->
      send(test, {:write, server, messages})
      :ok
    end)

    accept =
      Accept.new!(
        id: "accept-id-1",
        dataset_id: "test-ds1",
        subset_id: "test-ss1",
        destination: "test-ds1-raw",
        connection: Accept.Udp.new!(port: 6789)
      )

    Brook.Test.send(@instance, accept_start(), "testing", accept)

    assert_receive {:write, ^dummy_writer, messages, [dataset_id: "test-ds1"]}, 10_000

#    assert accept == Receive.Acception.Store.get!(accept.dataset_id, accept.subset_id)
  end
end
