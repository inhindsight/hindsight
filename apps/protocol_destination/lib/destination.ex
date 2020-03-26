defprotocol Destination do
  @type init_opts :: [
          dictionary: Dictionary.t(),
          app_name: String.t(),
          dataset_id: String.t(),
          subset_id: String.t()
        ]

  @spec start_link(t, init_opts) :: {:ok, t} | {:error, term}
  def start_link(t, opts)

  @spec write(t, messages :: list(map)) :: :ok | {:error, term}
  def write(t, messages)

  @spec stop(t) :: :ok
  def stop(t)

  @spec delete(t) :: :ok | {:error, term}
  def delete(t)
end
