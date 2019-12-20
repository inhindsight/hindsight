defmodule Http.HeaderTest do
  use ExUnit.Case

  import ExUnit.CaptureLog, only: [capture_log: 1]

  alias Extract.Context

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

  test "logs warning if no response is available" do
    step = %Http.Header{name: "header1", into: "variable1"}

    output =
      capture_log(fn ->
        {:ok, context} = Extract.Step.execute(step, Context.new())
        assert nil == Map.get(context.variables, "variable1")
      end)

    assert output =~ "No response is available to execute step"
  end
end
