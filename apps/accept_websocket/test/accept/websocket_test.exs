defmodule Accept.WebsocketTest do
  use ExUnit.Case
  doctest Accept.Websocket

  test "serialization" do
    websocket_conn = Accept.Websocket.new!(port: 8080, path: "/socket")

    serialized = JsonSerde.serialize!(websocket_conn)

    assert JsonSerde.deserialize!(serialized) == websocket_conn
  end
end
