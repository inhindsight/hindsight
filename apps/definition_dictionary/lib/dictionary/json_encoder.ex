defmodule Dictionary.JsonEncoder do
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
