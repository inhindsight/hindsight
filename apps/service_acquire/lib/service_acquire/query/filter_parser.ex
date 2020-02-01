defmodule Acquire.Query.FilterParser do
  import NimbleParsec

  @type operator :: "=" | "!=" | "<" | "<=" | ">" | ">="

  @spec parse_operation(input :: String.t()) :: {operator, [String.t(), String.t()]}
  def parse_operation(input) do
    {:ok, [left, op, right], _, _, _, _} = operator(input)

    {op, [left, right]}
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
