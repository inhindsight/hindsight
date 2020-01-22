defmodule Transform.Steps do
  alias Transform.Steps.Context

  @type t :: %__MODULE__{
          steps: [{Dictionary.t(), Transform.Step.t()}],
          dictionary: Dictionary.t()
        }

  defstruct steps: [],
            dictionary: nil

  @spec prepare([Transform.Step.t()], Dictionary.t()) :: {:ok, t} | {:error, term}
  def prepare(steps, dictionary) do
    Ok.reduce(steps, %__MODULE__{dictionary: dictionary}, fn step, acc ->
      with {:ok, new_dictionary} <- Transform.Step.transform_dictionary(step, acc.dictionary) do
        %{acc | dictionary: new_dictionary, steps: [{acc.dictionary, step} | acc.steps]}
        |> Ok.ok()
      end
    end)
    |> Ok.map(fn acc -> %{acc | steps: Enum.reverse(acc.steps)} end)
  end

  @spec transform(t, list(map)) :: {:ok, Enumerable.t()} | {:error, term}
  def transform(%__MODULE__{steps: steps}, values) do
    context = Context.new(values)

    Ok.reduce(steps, context, fn {dictionary, step}, ctx ->
      Transform.Step.transform(step, Context.set_dictionary(ctx, dictionary))
    end)
    |> Ok.map(&Context.get_stream/1)
  end

  @spec outgoing_dictionary(t) :: Dictionary.t()
  def outgoing_dictionary(steps) do
    Map.get(steps, :dictionary)
  end
end
