defprotocol Destination do
  @spec start_link(t, Destination.Context.t()) :: {:ok, t} | {:error, term}
  def start_link(t, context)

  @spec write(t, messages :: list(term)) :: :ok | {:error, term}
  def write(t, messages)

  @spec stop(t) :: :ok
  def stop(t)

  @spec delete(t) :: :ok | {:error, term}
  def delete(t)
end
