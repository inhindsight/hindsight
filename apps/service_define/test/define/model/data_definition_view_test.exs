defmodule DataDefinitionViewTest do
  use ExUnit.Case

  alias Define.Model.DataDefinitionView

  test "default values are valid" do
    assert {:ok, _} = DataDefinitionView.new([])
  end
end
