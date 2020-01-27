defmodule Transform.Test.Steps do
  defmodule SimpleRename do
    defstruct [:from, :to]

    defimpl Transform.Step, for: __MODULE__ do
      def transform_dictionary(%{from: from, to: to}, dictionary) do
        Dictionary.update_field(dictionary, from, fn field ->
          %{field | name: to}
        end)
        |> Ok.ok()
      end

      def transform_function(%{from: from, to: to}, _dictionary) do
        fn value ->
          value
          |> Map.put(to, Map.get(value, from))
          |> Map.delete(from)
        end
        |> Ok.ok()
      end
    end
  end

  defmodule Error do
    defstruct [:error]

    defimpl Transform.Step, for: __MODULE__ do
      def transform_dictionary(%{error: error}, _) do
        {:error, error}
      end

      def transform_function(%{error: error}, _) do
        {:error, error}
      end
    end
  end

  defmodule TransformStream do
    defstruct [:transform]

    defimpl Transform.Step, for: __MODULE__ do
      def transform_dictionary(_, dictionary) do
        Ok.ok(dictionary)
      end

      def transform_function(%{transform: transform}, _dictionary) do
        fn value ->
          transform.(value)
        end
        |> Ok.ok()
      end
    end
  end

  defmodule TransformInteger do
    defstruct [:name, :transform]

    defimpl Transform.Step, for: __MODULE__ do
      def transform_dictionary(_, dictionary) do
        Ok.ok(dictionary)
      end

      def transform_function(%{name: name, transform: transform}, dictionary) do
        field = Dictionary.get_field(dictionary, name)

        case validate_struct(field, Dictionary.Type.Integer) do
          true ->
            fn value ->
              transform.(value)
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
