defmodule Accept.WebsocketTest do
  use ExUnit.Case
  import Checkov
  doctest Accept.Websocket

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Accept.Websocket.new()

      where([
        [:field, :value],
        [:version, "1"],
        [:port, 100_000],
        [:port, nil],
        [:port, "8080"],
        [:path, ""],
        [:path, nil],
        [:idle_timeout, "8080"],
        [:idle_timeout, -10_000],
        [:hibernate, "false"],
        [:hibernate, 1]
      ])
    end
  end

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
