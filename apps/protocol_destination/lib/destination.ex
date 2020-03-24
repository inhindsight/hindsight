defprotocol Destination do
  @spec start_link(t, dictionary :: Dictionary.t()) :: {:ok, t} | {:error, term}
  def start_link(t, dictionary)

  @spec write(t, dictionary :: Dictionary.t(), messages :: list(map)) :: :ok | {:error, term}
  def write(t, dictionary, messages)

  @spec stop(t) :: :ok
  def stop(t)

  @spec delete(t) :: :ok | {:error, term}
  def delete(t)
end
