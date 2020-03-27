defprotocol Decoder do
  @spec decode(t, Enum.t()) :: Enum.t()
  def decode(t, stream)
end
