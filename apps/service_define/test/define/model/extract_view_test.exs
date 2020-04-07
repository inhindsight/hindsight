defmodule ExtractViewTest do
  use ExUnit.Case

  alias Define.Model.ExtractView

  test "default values are valid" do
    assert {:ok, _} = ExtractView.new([])
  end
end
