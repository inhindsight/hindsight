defmodule Accept.Udp.SocketTest do
  use ExUnit.Case

  setup do
    port = 6789
    source_opts = [port: port]

    destination = Destination.Fake.new!()
    writer = &Destination.write(destination, &1)

    udp_opts = [
      port: port,
      writer: writer,
      batch_size: 25,
      timeout: 500
    ]

    start_supervised({Accept.Udp.Socket, udp_opts})
    start_supervised({SourceUdpSocket, source_opts})

    :ok
  end

  test "reads from the incoming socket within the timeout" do
    Enum.each(1..10, fn _ -> SourceUdpSocket.hit_me() end)

    assert_receive({:destination_write, messages}, 600)
    assert length(messages) == 10
    assert Enum.all?(messages, fn msg -> "{\"payload\":" <> _random = msg end)
  end

  test "sends a full batch within the timeout" do
    Enum.each(1..30, fn _ -> SourceUdpSocket.hit_me() end)

    assert_receive({:destination_write, messages}, 500)
    assert length(messages) == 25
  end
end
