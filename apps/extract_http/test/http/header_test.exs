defmodule Http.HeaderTest do
  use ExUnit.Case

  alias Extract.Steps.Context

  test "retrieves header value from latest response and creates variable" do
    step = %Http.Header{name: "header1", into: "variable1"}

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
    step = %Http.Header{name: "header1", into: "variable1"}
    {:error, reason} = Extract.Step.execute(step, Context.new())

    assert reason ==
             Extract.InvalidContextError.exception(
               message: "Response is not available in context.",
               step: step
             )
  end

  test "returns error when header is not set in response" do
    step = %Http.Header{name: "header1", into: "variable1"}
    response = %Tesla.Env{}
    context = Context.new() |> Context.set_response(response)
    {:error, reason} = Extract.Step.execute(step, context)

    assert reason ==
             Http.Header.HeaderNotAvailableError.exception(
               message: "Header not available",
               header: "header1",
               response: response
             )
  end
end
