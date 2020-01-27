defmodule Transform.RenameField do
  defstruct [:from, :to]

  defimpl Transform.Step, for: __MODULE__ do
    def transform_dictionary(%{from: from, to: to}, dictionary) do
      from_path = to_path(from)

      update_in(dictionary, from_path, &change_name(&1, to))
      |> Ok.ok()
    end

    def transform_function(%{from: from, to: to}, _dictionary) do
      from_path = to_path(from)
      to_path = List.replace_at(from_path, -1, key(to))

      fn stream ->
        stream
        |> Enum.map(fn entry ->
          {value, updated_entry} = get_and_update_in(entry, from_path, fn _ -> :pop end)
          put_in(updated_entry, to_path, value)
        end)
      end
      |> Ok.ok()
    end

    defp to_path(name) do
      name
      |> String.split(".")
      |> Enum.map(&key/1)
    end

    defp change_name(nil, _), do: nil

    defp change_name(field, to) do
      %{field | name: to}
    end

    defp key(name) do
      Dictionary.Access.key(name, [], spread: true)
    end
  end
end