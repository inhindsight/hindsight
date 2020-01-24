defmodule Transform.DeleteFields do
  defstruct [:names]

  defimpl Transform.Step, for: __MODULE__ do
    def transform_dictionary(%{names: names}, dictionary) do
      names
      |> convert_to_paths()
      |> delete_paths(dictionary)
      |> Ok.ok()
    end

    def transform(%{names: names}, _dictionary, stream) do
      paths = convert_to_paths(names)

      stream
      |> Stream.map(&delete_paths(paths, &1))
      |> Ok.ok()
    end

    defp convert_to_paths(names) do
      Enum.map(names, &String.split(&1, "."))
    end

    defp delete_paths(paths, data) do
      Enum.reduce(paths, data, fn path, payload ->
        {_, new_data} = pop_in(payload, path)
        new_data
      end)
    end
  end
end
