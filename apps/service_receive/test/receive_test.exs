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
      set: [writer: Receive.WriterMock, batch_size: 10]
    }
  ])

  setup :set_mox_global
  setup :verify_on_exit!

  describe "Receive Udp" do
    setup do
      start_supervised({SourceUdpSocket, port: 6789, schedule: true, interval: 100})
      {:ok, dummy_writer} = start_supervised({Agent, fn -> :dummy_writer end})
      test = self()

      Receive.WriterMock
      |> stub(:start_link, fn args ->
        send(test, {:start_link, args})
        {:ok, dummy_writer}
      end)
      |> stub(:write, fn server, messages, opts ->
        send(test, {:write, server, messages, opts})
        :ok
      end)

      accept =
        Accept.new!(
          id: "accept-id-1",
          dataset_id: "test-ds1",
          subset_id: "test-ss1",
          destination: "test-ds1",
          connection: Accept.Udp.new!(port: 6789)
        )

      on_exit(fn ->
        Receive.Accept.Supervisor.kill_all_children()
      end)

      [accept: accept, dummy: dummy_writer]
    end

    setup do
      on_exit(fn ->
        Brook.Test.clear_view_state(@instance, "accepts")
      end)

      :ok
    end

    test "receives data from source", %{accept: accept, dummy: dummy} do
      Brook.Test.send(@instance, accept_start(), "testing", accept)

      assert_receive {:write, ^dummy, messages, [dataset_id: "test-ds1", subset_id: "test-ss1"]},
                    5_000

      assert length(messages) == 10

      assert accept == Receive.Accept.Store.get!(accept.dataset_id, accept.subset_id)
    end

    test "removes stored receipt on #{accept_end()}", %{accept: accept} do
      Brook.Test.send(@instance, accept_start(), "testing", accept)
      Process.sleep(100)

      Brook.Test.send(@instance, accept_end(), "testing", accept)

      assert_async do
        assert nil == Receive.Accept.Store.get!(accept.dataset_id, accept.subset_id)
      end
    end
  end

  describe "Receive Websocket" do
    setup do
      {:ok, client} = start_supervised({SourceWebSocket, port: 6789, host: "localhost", path: "/receive/ws"})
      {:ok, dummy_writer} = start_supervised({Agent, fn -> :dummy_writer end})
      test = self()

      Receive.WriterMock
      |> stub(:start_link, fn args ->
        send(test, {:start_link, args})
        {:ok, dummy_writer}
      end)
      |> stub(:write, fn server, messages, opts ->
        send(test, {:write, server, messages, opts})
        :ok
      end)

      accept =
        Accept.new!(
          id: "accept-id-2",
          dataset_id: "test-ds2",
          subset_id: "test-ss2",
          destination: "test-ds2",
          connection: Accept.Websocket.new!(port: 6789, path: "/receive/ws")
        )

      on_exit(fn ->
        Receive.Accept.Supervisor.kill_all_children()
      end)

      [accept: accept, dummy: dummy_writer, client: client]
    end

    setup do
      on_exit(fn ->
        Brook.Test.clear_view_state(@instance, "accepts")
      end)

      :ok
    end

    test "receives data from source", %{accept: accept, dummy: dummy, client: client} do
      Brook.Test.send(@instance, accept_start(), "testing", accept)

      assert_async do
        Enum.map(0..9, fn int -> SourceWebSocket.push(client, "msg#{int}") end)

        assert_receive {:write, ^dummy, messages, [dataset_id: "test-ds2", subset_id: "test-ss1"]}

        assert length(messages) == 10

        assert accept == Receive.Accept.Store.get!(accept.dataset_id, accept.subset_id)
      end
    end
  end
end
