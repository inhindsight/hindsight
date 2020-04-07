defmodule AppViewTest do
  use ExUnit.Case

  alias Define.Model.AppView

  test "default values are valid" do
    assert {:ok, _} = AppView.new([])
  end
end
