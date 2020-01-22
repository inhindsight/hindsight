defmodule Transform.Test.Steps do
  defmodule SimpleRename do
    defstruct [:from, :to]

    defimpl Transform.Step, for: __MODULE__ do
      import Transform.Steps.Context

      def transform_dictionary(%{from: from, to: to}, dictionary) do
        Dictionary.update_field(dictionary, from, fn field ->
          %{field | name: to}
        end)
        |> Ok.ok()
      end

      def transform(%{from: from, to: to}, context) do
        new_stream =
          get_stream(context)
          |> Stream.map(fn entry ->
            entry
            |> Map.put(to, Map.get(entry, from))
            |> Map.delete(from)
          end)

        context
        |> set_stream(new_stream)
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

      def transform(%{error: error}, _) do
        {:error, error}
      end
    end
  end

  defmodule TransformStream do
    defstruct [:transform]

    defimpl Transform.Step, for: __MODULE__ do
      import Transform.Steps.Context

      def transform_dictionary(_, dictionary) do
        Ok.ok(dictionary)
      end

      def transform(%{transform: transform}, context) do
        new_stream =
          get_stream(context)
          |> Stream.map(transform)

        context
        |> set_stream(new_stream)
        |> Ok.ok()
      end
    end
  end

  defmodule TransformInteger do
    defstruct [:name, :transform]

    defimpl Transform.Step, for: __MODULE__ do
      import Transform.Steps.Context

      def transform_dictionary(_, dictionary) do
        Ok.ok(dictionary)
      end

      def transform(%{name: name, transform: transform}, context) do
        dictionary = get_dictionary(context)
        field = Dictionary.get_field(dictionary, name)

        case validate_struct(field, Dictionary.Type.Integer) do
          true ->
            new_stream =
              get_stream(context)
              |> Stream.map(transform)

            context
            |> set_stream(new_stream)
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
