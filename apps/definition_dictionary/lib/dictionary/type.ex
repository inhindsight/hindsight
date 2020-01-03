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

  @spec from_string(String.t()) :: module
  def from_string(string) do
  end
end
