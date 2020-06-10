defmodule Extract.Http.PostTest do
  use ExUnit.Case
  import Plug.Conn
  import Checkov

  alias Extract.Context

  @moduletag capture_log: true

  setup do
    [bypass: Bypass.open()]
  end

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Extract.Http.Post.new()

      where([
        [:field, :value],
        [:version, "1"],
        [:url, ""],
        [:url, nil],
        [:headers, nil],
        [:headers, ""],
        [:body, 1]
      ])
    end
  end

  test "serialization" do
    post =
      Extract.Http.Post.new!(
        url: "http://localhsot",
        headers: %{"name" => "some_name"},
        body: "hello"
      )

    serialized = JsonSerde.serialize!(post)

    assert JsonSerde.deserialize!(serialized) == post
  end

  describe "Extract.Step" do
    test "execute will send request and set in context", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/post/123", fn conn ->
        {:ok, body, _} = read_body(conn)
        assert body == "Hello Joe Joe"
        assert ["value1"] == get_req_header(conn, "header1")

        resp(conn, 200, "goodbye")
      end)

      step = %Extract.Http.Post{
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

      expected_message = Extract.Message.new(data: "goodbye")
      assert [[expected_message]] == Context.get_stream(context) |> Enum.to_list()
    end

    test "execute will return error tuple for any status != 200", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/post-request", fn conn ->
        resp(conn, 404, "Not Found")
      end)

      step = %Extract.Http.Post{
        url: "http://localhost:#{bypass.port}/post-request",
        body: "hello"
      }

      assert {:error, %Extract.Http.File.Downloader.InvalidStatusError{}} =
               Extract.Step.execute(step, Context.new())
    end

    test "execute will return error tuple when error occurred during get" do
      step = %Extract.Http.Post{url: "http://localhost/get-request", body: "hello"}
      reason = Mint.TransportError.exception(reason: :econnrefused)
      assert {:error, reason} == Extract.Step.execute(step, Context.new())
    end
  end
end
