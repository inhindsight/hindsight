defprotocol Source do
  @spec start_link(t, dictionary :: Dictionary.t(), ([map] -> :ok)) :: {:ok, t} | {:error, term}
  def start_link(t, dictionary, handler_function)

  @spec delete(t) :: :ok | {:error, term}
  def delete(t)
end
