defmodule Acquire.Query.Where.FilterParser do
  import NimbleParsec

  alias Acquire.Query.Where.{Function, Parameter, Field}

  @spec parse_operation(input :: String.t()) :: {:ok, Function.t()} | {:error, term}
  def parse_operator(""), do: Ok.ok([])

  def parse_operation(input) do
    with {:ok, [left, op, right], _, _, _, _} <- operator(input),
         {:ok, field} <- Field.new(name: left),
         {:ok, parameter} <- Parameter.new(value: right) do
      Function.new(function: op, args: [field, parameter])
    end
  end

  defparsec :operator,
            empty()
            |> ascii_string([?A..?z, ?0..?9], min: 1)
            |> choice([
              string(">="),
              string("<="),
              string("!="),
              string("="),
              string(">"),
              string("<")
            ])
            |> ascii_string([?A..?z, ?0..?9, ?\s, ?.], min: 1)
            |> eos()
end
