defmodule Transform.AddTimestampField do
  @moduledoc """
  `Transform.Step` impl to add a timestamp field to a dataset. Timestamps will be stored in ISO-8601 format.

  ## Configuration
  * `name` - Required. Key path to new timestamp field location in the data. You can specify a top level key (`"field_name"`)
             or nest the field with a list of keys (`["top_level_key", "next_level_key", "field_name"]`).
  """
  use Definition, schema: Transform.AddTimestampField.V1

  @type t :: %__MODULE__{
          name: String.t() | [String.t()]
        }

  defstruct name: nil,
            description: ""

  defimpl Transform.Step, for: __MODULE__ do
    import Dictionary.Access, only: [to_access_path: 1, to_access_path: 2]

    def transform_dictionary(%{name: name, description: description}, dictionary) do
      with {:ok, timestamp} <- Dictionary.Type.Timestamp.new(name: name, description: description) do
        put_in(dictionary, to_access_path(name), timestamp)
        |> Ok.ok()
      end
    end

    def create_function(%{name: name}, _dictionary) do
      to_path = to_access_path(name, spread: true)

      fn record ->
        now = NaiveDateTime.utc_now() |> NaiveDateTime.to_iso8601()
        put_in(record, to_path, now)
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
