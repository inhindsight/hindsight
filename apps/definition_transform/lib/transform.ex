defmodule Transform do
  use Definition, schema: Transform.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
          version: integer,
          id: uuid,
          dataset_id: String.t(),
          subset_id: String.t(),
          dictionary: Dictionary.t(),
          steps: list
        }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            subset_id: nil,
            dictionary: Dictionary.from_list([]),
            steps: []

  @impl Definition
  def on_new(%{dictionary: list} = transform) when is_list(list) do
    Map.put(transform, :dictionary, Dictionary.from_list(list))
    |> my_on_new()
  end

  def on_new(transform), do: my_on_new(transform)

  defp my_on_new(transform = %{id: nil}) do
    Map.put(transform, :id, UUID.uuid4())
    |> Ok.ok()
  end

  defp my_on_new(transform) do
    Ok.ok(transform)
  end
end
