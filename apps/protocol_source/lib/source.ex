defprotocol Source do
  @type init_opts :: [
          dictionary: Dictionary.t(),
          handler: SourceHandler.impl(),
          app_name: String.t(),
          dataset_id: String.t(),
          subset_id: String.t(),
          context: term
        ]

  @spec start_link(t, init_opts) :: {:ok, t} | {:error, term}
  def start_link(t, init_opts)

  @spec stop(t) :: :ok
  def stop(t)

  @spec delete(t) :: :ok | {:error, term}
  def delete(t)
end
