defmodule Load.Persist do
  use Definition, schema: Load.Persist.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
          version: integer,
          id: uuid,
          dataset_id: uuid,
          name: String.t(),
          source: String.t(),
          destination: String.t(),
          schema: list()
        }

  @derive Jason.Encoder
  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            name: nil,
            source: nil,
            destination: nil,
            schema: []

  def on_new(%__MODULE__{schema: []} = persist), do: Ok.ok(persist)

  def on_new(%__MODULE__{schema: schema} = persist) when is_list(schema) do
    case Dictionary.decode(schema) do
      {:ok, new_schema} -> Map.put(persist, :schema, new_schema) |> Ok.ok()
      error -> error
    end
  end

  def on_new(persist), do: Ok.ok(persist)
end

defmodule Load.Persist.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Load.Persist{
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
