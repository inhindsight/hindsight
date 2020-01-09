defmodule Extract.Steps do
  @spec execute(Enum.t()) :: {:ok, Enum.t()} | {:error, term}
  def execute(steps) do
    steps
    |> parse_steps()
    |> Ok.reduce(Extract.Steps.Context.new(), &Extract.Step.execute/2)
    |> Ok.map(fn c -> c.stream end)
  rescue
    e -> {:error, error_message(e)}
  end

  defp parse_steps(steps) do
    steps
    |> Enum.map(&to_atom_keys/1)
    |> Enum.map(fn step ->
      :"Elixir.#{Map.get(step, :step)}"
      |> struct!(Map.delete(step, :step))
    end)
  end

  defp to_atom_keys(map) do
    for {k, v} <- map, do: {to_atom(k), v}, into: %{}
  end

  defp to_atom(word) when is_atom(word), do: word
  defp to_atom(word), do: String.to_existing_atom(word)

  defp error_message(e) do
    case Exception.exception?(e) do
      true -> Exception.message(e)
      false -> e
    end
  end
end
