defmodule Define.TypespecAnalysisTest do
  use ExUnit.Case
  alias Define.{TypespecAnalysis}

  describe "get_types/1" do
    test "returns all types from the typespec" do
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

    test "returns empty map when a typespec is not defined" do
      assert %{} == TypespecAnalysis.get_types(TypespecAnalysisTestModuleNoSpec)
    end
  end
end
