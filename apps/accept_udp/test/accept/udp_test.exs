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

  test "serialization" do
    udp_conn = Accept.Udp.new!(port: 5060)

    serialized = JsonSerde.serialize!(udp_conn)

    assert JsonSerde.deserialize!(serialized) == udp_conn
  end
end
