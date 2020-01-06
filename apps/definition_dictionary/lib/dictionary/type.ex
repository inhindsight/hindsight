defmodule Dictionary.Type do
  import Kernel, except: [to_string: 1]

  @spec to_string(module) :: String.t()
  def to_string(type) do
    type
    |> Kernel.to_string()
    |> String.split(".")
    |> List.last()
    |> String.downcase()
  end

  @spec from_string(String.t()) :: {:ok, module} | {:error, term}
  def from_string(string) when is_binary(string) do
    with module <- :"Elixir.Dictionary.Type.#{String.capitalize(string)}",
         {:module, _} <- Code.ensure_loaded(module),
         {:struct?, true} <- {:struct?, function_exported?(module, :__struct__, 0)} do
      Ok.ok(module)
    else
      {:error, _e} -> invalid_type(string)
      {:struct?, false} -> invalid_type(string)
    end
  end

  defp invalid_type(type) do
    Dictionary.InvalidTypeError.exception(message: "#{type} is not a valid type")
    |> Ok.error()
  end
end
