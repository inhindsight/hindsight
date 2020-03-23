defmodule Define.ProtocolFinderTest do
  use ExUnit.Case
  alias Define.{ProtocolFinder}

  test "It does what's expected of it" do
    expected = %{
      "integer_type" => "integer",
      "string_type" => "string",
      "atom_type" => "atom",
      "float_type" => "float",
      "string_list_type" => {"list", "string"},
      "integer_list_type" => {"list", "integer"},
      "map_type" => "map"
    }

    assert expected == ProtocolFinder.get_types(TestModule)
  end
end
