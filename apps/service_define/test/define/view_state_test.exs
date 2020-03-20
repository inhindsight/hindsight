defmodule Define.ViewStateTest do
  use ExUnit.Case
  alias Define.ViewState

  setup do
    server = start_supervised!(ViewState)
    {:ok, server: server}
  end

  test "when new_greeting event sets the greeting", %{server: server} do
    ui_state = ViewState.event(server, "new_greeting", %{"greeting" => "Hello World!"})

    assert ui_state == %{"greeting" => "Hello World!"}
  end
end
