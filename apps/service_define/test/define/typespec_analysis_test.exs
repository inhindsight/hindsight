defmodule Define.TypespecAnalysisTest do
  use ExUnit.Case
  alias Define.{TypespecAnalysis}

  test "get_types() returns all types from the typespec" do
    expected = %{
      "integer_type" => "integer",
      "string_type" => "string",
      "atom_type" => "atom",
      "float_type" => "float",
      "string_list_type" => {"list", "string"},
      "integer_list_type" => {"list", "integer"},
      "map_type" => "map",
      "dictionary_type" => "dictionary"
    }

    assert expected == TypespecAnalysis.get_types(TypespecAnalysisTestModule)
  end
end
