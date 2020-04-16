defmodule Dictionary.JsonEncoder do
  @moduledoc """
  Helper module to ensure `Dictionary.Type.*` structs can be encoded to JSON.
  """
  defmacro __using__(_opts) do
    quote do
      defimpl Jason.Encoder, for: __MODULE__ do
        def encode(%struct_module{} = value, opts) do
          Map.from_struct(value)
          |> Map.put("type", Dictionary.Type.to_string(struct_module))
          |> Jason.Encode.map(opts)
        end
      end
    end
  end
end
