defmodule ViewStateTest do
  use ExUnit.Case

  setup do
    server = start_supervised!(ViewState.Server)
    {:ok, server: server}
  end

  test "when new_gretting event sets the greeting", %{ server: server } do

    ui_state = ViewState.Client.event(server, %{ "type" => "new_greeting", "greeting" => "Hello World!" })

    assert ui_state == %{ "greeting" => "Hello World!"}
  end
end
