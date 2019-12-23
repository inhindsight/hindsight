defmodule Load.Steps do
  @spec execute(Enum.t()) :: {:ok, Enum.t()} | {:error, term}
  def execute(steps) do
    steps
    |> parse_steps()
    |> Ok.reduce(Load.Steps.Context.new(), &Load.Step.execute/2)
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
