defprotocol Dictionary.Type.Decoder do
  @fallback_to_any true
  @spec decode(t, map) :: {:ok, t} | {:error, term}
  def decode(t, map)
end

defimpl Dictionary.Type.Decoder, for: Any do
  def decode(%struct{}, map) do
    map
    |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
    |> Map.new()
    |> struct.new()
  end
end
