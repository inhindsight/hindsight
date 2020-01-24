defmodule Transform.Steps do
  @type t :: %__MODULE__{
          function: (Enumerable.t() -> Enumberable.t()),
          dictionary: Dictionary.t()
        }

  defstruct function: nil,
            dictionary: nil

  @spec create_transformer([Transform.Step.t()], Dictionary.t()) :: {:ok, t} | {:error, term}
  def create_transformer(steps, dictionary) do
    initial = %__MODULE__{dictionary: dictionary, function: fn x -> x end}

    Ok.reduce(steps, initial, fn step, acc ->
      with {:ok, new_dictionary} <- Transform.Step.transform_dictionary(step, acc.dictionary),
           {:ok, transform_function} <- Transform.Step.transform_function(step, acc.dictionary) do
        %{
          acc
          | dictionary: new_dictionary,
            function: fn stream ->
              acc.function.(stream)
              |> transform_function.()
            end
        }
        |> Ok.ok()
      end
    end)
  end

  @spec transform(t, list(map)) :: {:ok, Enumerable.t()} | {:error, term}
  def transform(%__MODULE__{function: function}, values) do
    function.(values)
    |> Ok.ok()
  end

  @spec outgoing_dictionary(t) :: Dictionary.t()
  def outgoing_dictionary(steps) do
    Map.get(steps, :dictionary)
  end
end
