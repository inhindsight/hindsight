defmodule Transformer do
  @moduledoc """
  Executes `Transform.Step` impls to generate transformed dictionaries
  and functions used to transform data.
  """
  @type transform_function :: (map -> {:ok, map} | {:error, term})

  @type t :: %__MODULE__{
          function: transform_function,
          dictionary: Dictionary.t()
        }

  defstruct function: nil,
            dictionary: nil

  @spec transform_dictionary([Transform.Step.t()], Dictionary.t()) ::
          {:ok, Dictionary.t()} | {:error, term}
  def transform_dictionary(steps, dictionary) do
    Ok.reduce(steps, dictionary, fn step, acc ->
      Transform.Step.transform_dictionary(step, acc)
    end)
  end

  @spec create([Transform.Step.t()], Dictionary.t()) ::
          {:ok, transform_function} | {:error, term}
  def create(steps, dictionary) do
    initial = %__MODULE__{dictionary: dictionary, function: fn {:ok, x} -> Ok.ok(x) end}

    Ok.reduce(steps, initial, fn step, acc ->
      with {:ok, new_dictionary} <- Transform.Step.transform_dictionary(step, acc.dictionary),
           {:ok, transform_function} <- Transform.Step.create_function(step, acc.dictionary) do
        %{
          acc
          | dictionary: new_dictionary,
            function: fn value ->
              case acc.function.(value) do
                {:ok, new_value} -> transform_function.(new_value)
                error -> error
              end
            end
        }
        |> Ok.ok()
      end
    end)
    |> Ok.map(fn steps -> fn value -> transform(steps, value) end end)
  end

  defp transform(%__MODULE__{function: function}, value) do
    value
    |> Ok.ok()
    |> function.()
  end
end
