defmodule Http.GetTest do
  use ExUnit.Case
  import Plug.Conn

  alias Extract.Steps.Context

  @moduletag capture_log: true

  setup do
    [bypass: Bypass.open()]
  end

  test "execute will send request and set in context", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/get-request", fn conn ->
      resp(conn, 200, "hello")
    end)

    step = %Http.Get{url: "http://localhost:#{bypass.port}/get-request"}
    {:ok, context} = Extract.Step.execute(step, Context.new())

    assert ["hello"] == Context.get_stream(context) |> Enum.to_list()
  end

  test "execute will replace variables in url", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/get/foo", fn conn ->
      resp(conn, 200, "hello")
    end)

    step = %Http.Get{url: "http://localhost:#{bypass.port}/get/<id>"}
    context = Context.new() |> Context.add_variable("id", "foo")
    {:ok, context} = Extract.Step.execute(step, context)

    assert ["hello"] == Context.get_stream(context) |> Enum.to_list()
  end

  test "execute will add headers to request", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/get-request", fn conn ->
      assert ["value1"] == get_req_header(conn, "header1")

      resp(conn, 200, "hello")
    end)

    step = %Http.Get{
      url: "http://localhost:#{bypass.port}/get-request",
      headers: [{"header1", "<var1>"}]
    }

    context = Context.new() |> Context.add_variable("var1", "value1")
    {:ok, _context} = Extract.Step.execute(step, context)
  end

  test "execute will return error tuple for any status != 200", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/get-request", fn conn ->
      resp(conn, 404, "Not Found")
    end)

    step = %Http.Get{url: "http://localhost:#{bypass.port}/get-request"}

    assert {:error, %Http.File.Downloader.InvalidStatusError{}} =
             Extract.Step.execute(step, Context.new())
  end

  test "execute will return error tuple when error occurred during get" do
    step = %Http.Get{url: "http://localhost/get-request"}
    reason = Mint.TransportError.exception(reason: :econnrefused)
    assert {:error, reason} == Extract.Step.execute(step, Context.new())
  end
end
