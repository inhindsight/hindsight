defmodule Accept.UdpTest do
  use ExUnit.Case
  import Checkov
  doctest Accept.Udp

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Accept.Udp.new()

      where([
        [:field, :value],
        [:version, "1"],
        [:port, 100_000],
        [:port, nil],
        [:port, "8080"]
      ])
    end
  end

  describe "serialization" do
    test "can be decoded back into a struct" do
      udp_conn = Accept.Udp.new!(port: 5060)
      json = Jason.encode!(udp_conn)

      assert {:ok, ^udp_conn} = Jason.decode!(json) |> Accept.Udp.new()
    end

    test "brook serializer can (de)serialize" do
      udp_conn =
        Accept.Udp.new!(port: 5060)

      assert {:ok, ^udp_conn} =
               Brook.Serializer.serialize(udp_conn) |> elem(1) |> Brook.Deserializer.deserialize()
    end
  end
end
