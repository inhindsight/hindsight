defmodule Extract.Http.HeaderTest do
  use ExUnit.Case
  import Checkov

  alias Extract.Steps.Context

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Extract.Http.Header.new()

      where([
        [:field, :value],
        [:version, "1"],
        [:name, nil],
        [:name, ""],
        [:into, nil],
        [:into, ""]
      ])
    end
  end

  test "can be decoded back into struct" do
    struct = Extract.Http.Header.new!(name: "name", into: "NAME")
    json = Jason.encode!(struct)

    assert {:ok, struct} == Jason.decode!(json) |> Extract.Http.Header.new()
  end

  test "brook serializer can serialize and deserialize" do
    struct = Extract.Http.Header.new!(name: "name", into: "NAME")

    assert {:ok, struct} =
             Brook.Serializer.serialize(struct) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  describe "Extract.Step" do
    test "retrieves header value from latest response and creates variable" do
      step = %Extract.Http.Header{name: "header1", into: "variable1"}

      response = %Tesla.Env{
        headers: [{"header1", "value1"}, {"header2", "value2"}]
      }

      context =
        Context.new()
        |> Context.set_response(response)

      {:ok, context} = Extract.Step.execute(step, context)

      assert "value1" == Map.get(context.variables, "variable1")
    end

    test "returns error is response is not available" do
      step = %Extract.Http.Header{name: "header1", into: "variable1"}
      {:error, reason} = Extract.Step.execute(step, Context.new())

      assert reason ==
               Extract.InvalidContextError.exception(
                 message: "Response is not available in context.",
                 step: step
               )
    end

    test "returns error when header is not set in response" do
      step = %Extract.Http.Header{name: "header1", into: "variable1"}
      response = %Tesla.Env{}
      context = Context.new() |> Context.set_response(response)
      {:error, reason} = Extract.Step.execute(step, context)

      assert reason ==
               Extract.Http.Header.HeaderNotAvailableError.exception(
                 message: "Header not available",
                 header: "header1",
                 response: response
               )
    end
  end
end
