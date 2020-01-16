defmodule Load.Broadcast do
  use Definition, schema: Load.Broadcast.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
          version: integer,
          id: uuid,
          dataset_id: uuid,
          name: String.t(),
          source: String.t(),
          destination: String.t(),
          schema: list
        }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            name: nil,
            source: nil,
            destination: nil,
            schema: []

  def on_new(%__MODULE__{schema: []} = broadcast), do: Ok.ok(broadcast)

  def on_new(%__MODULE__{schema: schema} = broadcast) when is_list(schema) do
    case Dictionary.decode(schema) do
      {:ok, new_schema} -> Map.put(broadcast, :schema, new_schema) |> Ok.ok()
      error -> error
    end
  end

  def on_new(broadcast), do: Ok.ok(broadcast)
end

defmodule Load.Broadcast.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Load.Broadcast{
      version: version(1),
      id: id(),
      dataset_id: id(),
      name: required_string(),
      source: required_string(),
      destination: required_string(),
      schema: spec(is_list())
    })
  end
end
