defmodule Transform do
  @moduledoc """
  Object representing the transformation of dataset fields and values. Use `new/1` to
  create a new instance.

  ## Init options

  * `id` - ID of this instance of a schedule. Typically a UUID.
  * `dataset_id` - Dataset identifier.
  * `subset_id` - Dataset's subset identifier.
  * `dictionary` - A `Dictionary.t()` impl describing the data's schema.
  * `steps` - List of `Transform.Step.t()` impls to execute.
  """
  use Definition, schema: Transform.V1
  use JsonSerde, alias: "transform"

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
    |> Ok.ok()
  end

  def on_new(transform), do: Ok.ok(transform)
end
