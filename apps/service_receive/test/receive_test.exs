defmodule ReceiveTest do
  use ExUnit.Case
  import Events, only: [accept_start: 0]
  import Definition, only: [identifier: 1]
  import AssertAsync
  require Temp.Env

  @instance Receive.Application.instance()

  Temp.Env.modify([
    %{
      app: :service_receive,
      key: Receive.SocketManager,
      set: [batch_size: 10]
    }
  ])

  describe "Receive Udp" do
    setup do
      start_supervised({SourceUdpSocket, port: 6789, schedule: true, interval: 100})

      accept =
        Accept.new!(
          id: "accept-id-1",
          dataset_id: "test-ds1",
          subset_id: "test-ss1",
          destination: Destination.Fake.new!(),
          connection: Accept.Udp.new!(port: 6789)
        )

      on_exit(fn ->
        Receive.Accept.Supervisor.kill_all_children()
      end)

      [accept: accept]
    end

    setup do
      on_exit(fn ->
        Brook.Test.clear_view_state(@instance, "accepts")
      end)

      :ok
    end

    test "receives data from source", %{accept: accept} do
      Brook.Test.send(@instance, accept_start(), "testing", accept)

      assert_receive {:destination_start_link, id}, 5_000

      assert_receive {:destination_write, messages}, 5_000
      assert length(messages) == 10

      assert {:ok, ^accept} = Receive.ViewState.Accepts.get(identifier(accept))
    end
  end

  describe "Receive Websocket" do
    setup do
      accept =
        Accept.new!(
          id: "accept-id-2",
          dataset_id: "test-ds2",
          subset_id: "test-ss2",
          destination: Destination.Fake.new!(),
          connection: Accept.Websocket.new!(port: 6790, path: "/receive/ws")
        )

      on_exit(fn ->
        Receive.Accept.Supervisor.kill_all_children()
      end)

      [accept: accept]
    end

    setup do
      on_exit(fn ->
        Brook.Test.clear_view_state(@instance, "accepts")
      end)

      :ok
    end

    test "receives data from source", %{accept: accept} do
      Brook.Test.send(@instance, accept_start(), "testing", accept)

      {:ok, client} =
        start_supervised({SourceWebsocket, port: 6790, host: "localhost", path: "/receive/ws"})

      assert_async do
        Enum.map(0..10, fn int -> SourceWebsocket.push(client, "msg#{int}") end)
        assert_receive {:destination_write, messages}

        assert length(messages) == 10
        refute "msg10" in messages

        assert {:ok, ^accept} = Receive.ViewState.Accepts.get(identifier(accept))
      end

      flush_queue(client)
    end
  end

  defp flush_queue(client) do
    stop_supervised(client)
    Process.sleep(1_000)
  end
end
