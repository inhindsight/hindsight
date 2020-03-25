defprotocol Source do
  @spec start_link(t, Source.Context.t()) :: {:ok, t} | {:error, term}
  def start_link(t, context)

  @spec stop(t) :: :ok
  def stop(t)

  @spec delete(t) :: :ok | {:error, term}
  def delete(t)
end
