defmodule Transform.MoveField do
  @moduledoc """
  `Transform.Step` impl to move or rename a field
  in a dataset.

  ## Configuration

  * `from` - Required. Field to be moved. This can be a string or
  path. Ex: `"foo"` or `["foo", "bar", "baz"]`
  * `to` - Required. Where to move the field. This can be a string
  or path. Ex: `"abc"` or `["abc", "xyz"]`
  """
  use Definition, schema: Transform.MoveField.V1

  @type t :: %__MODULE__{
          from: String.t() | [String.t()],
          to: String.t() | [String.t()]
        }

  defstruct [:from, :to]

  defimpl Transform.Step, for: __MODULE__ do
    import Dictionary.Access, only: [to_access_path: 1, to_access_path: 2]

    def transform_dictionary(%{from: from, to: to}, dictionary) do
      from_path = to_access_path(from)
      to_path = to_access_path(to)
      new_name = List.wrap(to) |> List.last()

      {field, updated_dictionary} = get_and_update_in(dictionary, from_path, fn _ -> :pop end)
      updated_field = change_name(field, new_name)

      put_in(updated_dictionary, to_path, updated_field)
      |> Ok.ok()
    end

    def create_function(%{from: from, to: to}, _dictionary) do
      from_path = to_access_path(from, spread: true)
      to_path = to_access_path(to, spread: true)

      fn entry ->
        {value, updated_entry} = get_and_update_in(entry, from_path, fn _ -> :pop end)

        put_in(updated_entry, to_path, value)
        |> Ok.ok()
      end
      |> Ok.ok()
    end

    defp change_name(nil, _), do: nil

    defp change_name(field, to) do
      %{field | name: to}
    end
  end
end

defmodule Transform.MoveField.V1 do
  use Definition.Schema

  def s do
    schema(%Transform.MoveField{
      from: access_path(),
      to: access_path()
    })
  end
end
