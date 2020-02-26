defmodule Accept.Websocket.SocketTest do
  use ExUnit.Case
  import AssertAsync

  setup do
    test_pid = self()

    writer_function = fn payload ->
      send(test_pid, {:socket_payload, payload})
    end

    socket_opts = [
      writer: writer_function,
      hibernate: true,
      idle_timeout: 2_000,
      timeout: 1_000,
      batch_size: 5,
      path: "/receive/socket",
      port: 8080
    ]

    start_supervised({Accept.Websocket.Supervisor, socket_opts})

    {:ok, client} =
      start_supervised({SourceWebsocket, host: "localhost", path: "/receive/socket", port: 8080})

    [client: client]
  end

  test "receives messages and writes them in batches", %{client: client} do
    assert_async do
      Enum.map(0..6, fn int -> SourceWebsocket.push(client, "msg#{int}") end)

      assert_receive {:socket_payload, ["msg0", "msg1", "msg2", "msg3", "msg4"]}
    end
  end

  test "receives messages and writes after timeout", %{client: client} do
    assert_async do
      Enum.map(0..2, fn int -> SourceWebsocket.push(client, "msg#{int}") end)

      assert_receive {:socket_payload, ["msg0", "msg1", "msg2"]}, 2_000
    end
  end
end
