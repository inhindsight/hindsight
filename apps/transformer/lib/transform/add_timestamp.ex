defmodule Transform.AddTimestampField do
  @moduledoc """
  `Transform.Step` impl to add a timestamp field to a dataset. Timestamps will be stored in ISO-8601 format.

  ## Configuration
  * `name` - Required. Field name or path to store the timestamp under. Ex: `"timestamp"` or `["key1", "key2", "key3"]`
  """
  use Definition, schema: Transform.AddTimestampField.V1

  @type t :: %__MODULE__{
          name: String.t() | [String.t()]
        }

  defstruct name: nil,
            description: ""

  defimpl Transform.Step, for: __MODULE__ do
    import Dictionary.Access, only: [to_access_path: 1]

    def transform_dictionary(%{name: name, description: description}, dictionary) do
      with {:ok, timestamp} <- Dictionary.Type.Timestamp.new(name: name, description: description) do
        put_in(dictionary, to_access_path(name), timestamp)
        |> Ok.ok()
      end
    end

    def create_function(%{name: name}, _dictionary) do
      fn record ->
        now = NaiveDateTime.utc_now() |> NaiveDateTime.to_iso8601()

        Map.put(record, name, now)
        |> Ok.ok()
      end
      |> Ok.ok()
    end
  end
end

defmodule Transform.AddTimestampField.V1 do
  @moduledoc false
  use Definition.Schema

  def s do
    schema(%Transform.AddTimestampField{
      name: access_path(),
      description: string()
    })
  end
end
