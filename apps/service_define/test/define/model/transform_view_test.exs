defmodule TransformViewTest do
  use ExUnit.Case

  alias Define.Model.TransformView

  test "default values are valid" do
    assert {:ok, _} = TransformView.new([])
  end
end
