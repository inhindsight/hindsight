defmodule Acquire.QueryTest do
  use ExUnit.Case
  import Checkov

  alias Acquire.Query

  describe "new/1" do
    data_test "validates #{key} against bad input" do
      input = put_in(%{table: "a__b"}, [key], value)
      assert {:error, [%{path: [^key | _]} | _]} = Query.new(input)

      where [
        [:key, :value],
        [:table, ""],
        [:table, "foo"],
        [:fields, nil],
        [:fields, [""]],
        [:limit, -1]
      ]
    end
  end
end
