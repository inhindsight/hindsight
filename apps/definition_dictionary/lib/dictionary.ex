defmodule Dictionary do
  defmodule InvalidFieldError do
    defexception [:message, :field]
  end

  @spec encode(list) :: {:ok, String.t()} | {:error, term}
  def encode(fields) do
    Jason.encode(fields)
  end

  @spec decode(binary | list | map) :: {:ok, Dictionary.Type.Decoder.t()} | {:error, term}

  def decode(json) when is_binary(json) do
    with {:ok, decoded_json} <- Jason.decode(json) do
      decode(decoded_json)
    end
  end

  def decode(list) when is_list(list) do
    Ok.transform(list, &decode/1)
  end

  def decode(%{"type" => type} = field) do
    with struct_module <- type_struct(type),
         {:module, _} <- Code.ensure_loaded(struct_module),
         {:struct?, true} <- {:struct?, function_exported?(struct_module, :__struct__, 0)} do
      Dictionary.Type.Decoder.decode(struct(struct_module), field)
    else
      {:error, _e} ->
        invalid_type(type, field)
      {:struct?, false} ->
        invalid_type(type, field)
    end
  end

  defp type_struct(type) do
    :"Elixir.Dictionary.Type.#{String.capitalize(type)}"
  end

  defp invalid_type(type, field) do
    {:error,
     InvalidFieldError.exception(message: "#{type} is not a valid type", field: field)}
  end
end
