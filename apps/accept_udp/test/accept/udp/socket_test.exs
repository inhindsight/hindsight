defmodule Accept.Udp.SocketTest do
  use ExUnit.Case

  setup do
    test_pid = self()

    writer_function = fn payload ->
      send(test_pid, {:udp_payload, payload})
    end

    port = 6789

    udp_opts = %{
      connection: Accept.Udp.new!(port: port),
      writer: writer_function,
      batch_size: 25,
      timeout: 1_000
    }

    {:ok, receiver} = Accept.Udp.Socket.start_link(udp_opts)
    {:ok, source} = SourceSocket.start_link(port)

    on_exit(fn ->
      Process.exit(source, :kill)
      Process.exit(receiver, :kill)
    end)

    :ok
  end

  test "reads from the incoming socket within the timeout" do
    received =
      receive do
        {:udp_payload, messages} -> messages
      end

    assert length(received) == 9
    assert Enum.all?(received, fn msg -> "{\"payload\":" <> _random = msg end)
  end

  test "sends a full batch within the timeout" do
    Enum.each(0..20, fn _ -> SourceSocket.hit_me() end)

    assert_receive({:udp_payload, messages}, 800)
    assert length(messages) == 25
  end
end
