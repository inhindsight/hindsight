defmodule Acquire.Query.AndTest do
  use ExUnit.Case
  import Checkov

  alias Acquire.Query.{And, Function}

  describe "new/1" do
    data_test "validates against bad input" do
      input = put_in(%{}, [field], value)
      assert {:error, [%{path: [^field | _]} | _]} = And.new(input)

      where [
        [:field, :value],
        [:conditions, [true, false]],
        [:conditions, [Function.new!(function: "a", args: [1, 2]), true]]
      ]
    end
  end

end
