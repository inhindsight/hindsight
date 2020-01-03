defmodule Dictionary.JsonEncoder do
  defmacro __using__(_opts) do
    quote do
      defimpl Jason.Encoder, for: __MODULE__ do
        def encode(value, opts) do
          Map.from_struct(value)
          |> Map.put("type", type())
          |> Jason.Encode.map(opts)
        end

        defp type() do
          __MODULE__
          |> to_string()
          |> String.split(".")
          |> List.last()
          |> String.downcase()
        end
      end
    end
  end
end
