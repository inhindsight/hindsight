defmodule Definition.Schema.Type.Lowercase do
  defstruct []

  defimpl Norm.Conformer.Conformable do
    def conform(_spec, input, _path) when is_binary(input) do
      {:ok, String.downcase(input)}
    end

    def conform(_spec, input, path) do
      {:error, [Norm.Conformer.error(path, input, "is not a binary")]}
    end
  end
end
