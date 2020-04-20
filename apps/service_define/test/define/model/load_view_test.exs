defmodule LoadViewTest do
  use ExUnit.Case

  alias Define.Model.LoadView

  test "default values are valid" do
    assert {:ok, _} = LoadView.new([])
  end
end
