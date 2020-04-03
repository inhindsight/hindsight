defmodule Accept.WebsocketTest do
  use ExUnit.Case
  doctest Accept.Websocket

  describe "serialization" do
    test "can be decoded back into a struct" do
      websocket_conn = Accept.Websocket.new!(port: 8080, path: "/socket")
      json = Jason.encode!(websocket_conn)

      assert {:ok, ^websocket_conn} = Jason.decode!(json) |> Accept.Websocket.new()
    end

    test "brook serializer can (de)serialize" do
      websocket_conn = Accept.Websocket.new!(port: 8080, path: "/socket")

      assert {:ok, ^websocket_conn} =
               Brook.Serializer.serialize(websocket_conn)
               |> elem(1)
               |> Brook.Deserializer.deserialize()
    end
  end
end
