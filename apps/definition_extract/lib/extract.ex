defmodule Extract do
  use Definition, schema: Extract.V1

  defstruct version: nil,
            id: nil,
            dataset_id: nil,
            steps: []

  defmodule InvalidContextError do
    defexception [:message, :step]
  end

  defprotocol Step do
    @spec execute(step :: t, context :: Extract.Context.t()) ::
            {:ok, Extract.Context.t()} | {:error, term}
    def execute(step, context)
  end

  @spec execute_steps(Enum.t()) :: {:ok, Enum.t()} | {:error, term}
  def execute_steps(steps) do
    steps
    |> parse_steps()
    |> Ok.reduce(Extract.Context.new(), &Extract.Step.execute/2)
    |> Ok.map(fn c -> c.stream end)
  rescue
    e -> {:error, error_message(e)}
  end

  defp parse_steps(steps) do
    steps
    |> Enum.map(fn step ->
      :"Elixir.#{Map.get(step, :step)}"
      |> struct!(Map.delete(step, :step))
    end)
  end

  defp error_message(e) do
    case Exception.exception?(e) do
      true -> Exception.message(e)
      false -> e
    end
  end
end
