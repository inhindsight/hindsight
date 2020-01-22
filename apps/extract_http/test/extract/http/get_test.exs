defmodule Extract.Http.GetTest do
  use ExUnit.Case
  import Plug.Conn
  import Checkov

  alias Extract.Steps.Context

  @moduletag capture_log: true

  setup do
    [bypass: Bypass.open()]
  end

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Extract.Http.Get.new()

      where([
        [:field, :value],
        [:version, "1"],
        [:url, ""],
        [:url, nil],
        [:headers, nil],
        [:headers, ""]
      ])
    end
  end

  test "can be decoded back into struct" do
    get = Extract.Http.Get.new!(url: "http://localhsot", headers: %{"name" => "some_name"})
    json = Jason.encode!(get)

    assert {:ok, get} == Jason.decode!(json) |> Extract.Http.Get.new()
  end

  test "brook serializer can serialize and deserialize" do
    get = Extract.Http.Get.new!(url: "http://localhsot", headers: %{"name" => "some_name"})

    assert {:ok, get} =
             Brook.Serializer.serialize(get) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  describe "Extract.Step" do
    test "execute will send request and set in context", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/get-request", fn conn ->
        resp(conn, 200, "hello")
      end)

      step = %Extract.Http.Get{url: "http://localhost:#{bypass.port}/get-request"}
      {:ok, context} = Extract.Step.execute(step, Context.new())

      assert ["hello"] == Context.get_stream(context) |> Enum.to_list()
    end

    test "execute will replace variables in url", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/get/foo", fn conn ->
        resp(conn, 200, "hello")
      end)

      step = %Extract.Http.Get{url: "http://localhost:#{bypass.port}/get/<id>"}
      context = Context.new() |> Context.add_variable("id", "foo")
      {:ok, context} = Extract.Step.execute(step, context)

      assert ["hello"] == Context.get_stream(context) |> Enum.to_list()
    end

    test "execute will add headers to request", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/get-request", fn conn ->
        assert ["value1"] == get_req_header(conn, "header1")

        resp(conn, 200, "hello")
      end)

      step = %Extract.Http.Get{
        url: "http://localhost:#{bypass.port}/get-request",
        headers: %{"header1" => "<var1>"}
      }

      context = Context.new() |> Context.add_variable("var1", "value1")
      {:ok, _context} = Extract.Step.execute(step, context)
    end

    test "execute will return error tuple for any status != 200", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/get-request", fn conn ->
        resp(conn, 404, "Not Found")
      end)

      step = %Extract.Http.Get{url: "http://localhost:#{bypass.port}/get-request"}

      assert {:error, %Extract.Http.File.Downloader.InvalidStatusError{}} =
               Extract.Step.execute(step, Context.new())
    end

    test "execute will return error tuple when error occurred during get" do
      step = %Extract.Http.Get{url: "http://localhost/get-request"}
      reason = Mint.TransportError.exception(reason: :econnrefused)
      assert {:error, reason} == Extract.Step.execute(step, Context.new())
    end
  end
end
