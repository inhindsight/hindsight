defmodule Transform.AddTimestampField do
  @moduledoc """
  `Transform.Step` impl to add a timestamp field to a dataset. Timestamps will be stored in ISO-8601 format.

  ## Configuration
  * `name` - Required. Field name or path to store the timestamp under. Ex: `"timestamp"` or `["timestamp"]`
  """
  use Definition, schema: Transform.AddTimestampField.V1

  @type t :: %__MODULE__{
    name: String.t() | [String.t()]
  }

  defstruct [:name]

  defimpl Transform.Step, for: __MODULE__ do
    import Dictionary.Access, only: [to_access_path: 1]

    def transform_dictionary(%{name: name}, dictionary) do
      name_path = to_access_path(name)
      put_in(dictionary, name_path, Dictionary.Type.Timestamp.new!(%{
        name: name,
        format: "%FT%TZ"
      }))
      |>Ok.ok()
    end

    def create_function(%{name: name}, _dictionary) do
      Ok.ok(fn record -> Map.put(record, name, DateTime.utc_now() |> DateTime.to_iso8601()) end |> Ok.ok())
    end
  end
end

defmodule Transform.AddTimestampField.V1 do
  @moduledoc false
  use Definition.Schema

  def s do
    schema(%Transform.AddTimestampField{
      name: access_path()
    })
  end
end
