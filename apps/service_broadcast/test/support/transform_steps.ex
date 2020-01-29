defmodule Broadcast.Transformer.Test do
  import Dictionary.Access, only: [to_access_path: 1]

  defmodule SimpleRename do
    defstruct [:from, :to]

    defimpl Transformer.Step, for: __MODULE__ do
      def transform_dictionary(%{from: from, to: to}, dictionary) do
        from_path = to_access_path(from)
        to_path = to_access_path(to)
        new_name = List.wrap(to) |> List.last()

        update_in(dictionary, from_path, fn field ->
          %{field | name: new_name}
        end)
        |> Ok.ok()
      end

      def create_function(%{from: from, to: to}, _dictionary) do
        from_path = to_access_path(from)
        to_path = to_access_path(to)

        fn value ->
          {value, updated_value} = get_and_update_in(value, from_path, fn _ -> :pop end)

          put_in(updated_value, to_path, value)
          |> Ok.ok()
        end
        |> Ok.ok()
      end
    end
  end

  defmodule Error do
    defstruct error: nil, dictionary: false, function: false, transform: false

    defimpl Transformer.Step, for: __MODULE__ do
      def transform_dictionary(%{error: error} = step, dictionary) do
        case Map.get(step, :dictionary, false) do
          true -> {:error, error}
          false -> {:ok, dictionary}
        end
      end

      def create_function(%{error: error} = step, _) do
        case Map.get(step, :function, false) do
          true ->
            {:error, error}

          false ->
            fn value ->
              case Map.get(step, :transform, false) do
                true -> {:error, error}
                false -> Ok.ok(value)
              end
            end
            |> Ok.ok()
        end
      end
    end
  end

  defmodule TransformStream do
    defstruct [:name, :transform]

    defimpl Transformer.Step, for: __MODULE__ do
      def transform_dictionary(_, dictionary) do
        Ok.ok(dictionary)
      end

      def create_function(%{name: name, transform: transform}, _dictionary) do
        name_path = to_access_path(name)

        fn value ->
          update_in(value, name_path, fn x -> transform.(x) end)
          |> Ok.ok()
        end
        |> Ok.ok()
      end
    end
  end

  defmodule TransformInteger do
    defstruct [:name, :transform]

    defimpl Transformer.Step, for: __MODULE__ do
      def transform_dictionary(_, dictionary) do
        Ok.ok(dictionary)
      end

      def create_function(%{name: name, transform: transform}, dictionary) do
        field = Dictionary.get_field(dictionary, name)
        name_path = to_access_path(name)

        case validate_struct(field, Dictionary.Type.Integer) do
          true ->
            fn value ->
              update_in(value, name_path, fn x -> transform.(x) end)
              |> Ok.ok()
            end
            |> Ok.ok()

          false ->
            Ok.error("#{name} is not defined as an integer")
        end
      end

      defp validate_struct(%struct_module{}, struct_module), do: true
      defp validate_struct(_, _), do: false
    end
  end
end
