defmodule Transform.DeleteFields do
  use Definition, schema: Transform.DeleteFields.V1

  @type t :: %__MODULE__{
    names: list(String.t())
  }

  defstruct [:names]

  import Dictionary.Access, only: [key: 1]

  defimpl Transform.Step, for: __MODULE__ do
    def transform_dictionary(%{names: names}, dictionary) do
      names
      |> convert_to_paths()
      |> delete_paths(dictionary)
      |> Ok.ok()
    end

    def transform_function(%{names: names}, _dictionary) do
      paths = convert_to_paths(names)

      fn stream ->
        stream
        |> Stream.map(&delete_paths(paths, &1))
      end
      |> Ok.ok()
    end

    defp convert_to_paths(names) do
      Enum.map(names, fn name ->
        String.split(name, ".")
        |> Enum.map(&key/1)
      end)
    end

    defp delete_paths(paths, data) do
      Enum.reduce(paths, data, fn path, payload ->
        {_, new_data} = pop_in(payload, path)
        new_data
      end)
    end
  end
end

defmodule Transform.DeleteFields.V1 do
  use Definition.Schema

  def s do
    schema(
      names: coll_of(spec(is_binary()))
    )
  end
end
