defmodule ArgumentViewTest do
  use ExUnit.Case

  alias Define.Model.ArgumentView

  test "default values are valid" do
    assert {:ok, _} = ArgumentView.new([])
  end
end
