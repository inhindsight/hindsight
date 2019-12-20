defmodule Http.PostTest do
  use ExUnit.Case
  import Plug.Conn

  alias Extract.Context

  @moduletag capture_log: true

  setup do
    [bypass: Bypass.open()]
  end

  test "execute will send request and set in context", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/post/123", fn conn ->
      {:ok, body, _} = read_body(conn)
      assert body == "Hello Joe Joe"
      assert ["value1"] == get_req_header(conn, "header1")

      resp(conn, 200, "goodbye")
    end)

    step = %Http.Post{
      url: "http://localhost:#{bypass.port}/post/<id>",
      body: "Hello <name> <name>",
      headers: [{"header1", "<header_value>"}]
    }

    context =
      Context.new()
      |> Context.add_variable("name", "Joe")
      |> Context.add_variable("id", "123")
      |> Context.add_variable("header_value", "value1")

    {:ok, context} = Extract.Step.execute(step, context)

    assert ["goodbye"] == Enum.to_list(context.stream)
  end

  test "execute will return error tuple for any status != 200", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/post-request", fn conn ->
      resp(conn, 404, "Not Found")
    end)

    step = %Http.Post{url: "http://localhost:#{bypass.port}/post-request", body: "hello"}
    reason = "HTTP POST to http://localhost:#{bypass.port}/post-request returned a 404 status"
    assert {:error, reason} == Extract.Step.execute(step, Context.new())
  end

  test "execute will return error tuple when error occurred during get" do
    step = %Http.Post{url: "http://localhost/get-request", body: "hello"}
    reason = Mint.TransportError.exception(reason: :econnrefused)
    assert {:error, reason} == Extract.Step.execute(step, Context.new())
  end
end
