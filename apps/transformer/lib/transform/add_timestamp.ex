defmodule Transform.AddTimestamp do
  use Definition, schema: Transform.AddTimestamp.V1

  defstruct [:name]

  defimpl Transform.Step do
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
      Ok.ok(fn record -> Map.put(record, name, DateTime.utc_now() |> DateTime.to_iso8601()) end)
    end
  end
end

defmodule Transform.AddTimestamp.V1 do
  use Definition.Schema

  def s do
    schema(%Transform.AddTimestamp{
      name: access_path()
    })
  end
end
