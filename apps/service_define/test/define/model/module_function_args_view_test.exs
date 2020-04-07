defmodule ModuleFunctionArgsViewTest do
  use ExUnit.Case

  alias Define.Model.ModuleFunctionArgsView

  test "default values are valid" do
    assert {:ok, _} = ModuleFunctionArgsView.new([])
  end
end
