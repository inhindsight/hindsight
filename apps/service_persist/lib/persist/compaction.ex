defmodule Persist.Compaction do
  use GenServer, restart: :transient
  use Properties, otp_app: :service_persist
  require Logger

  @instance Persist.Application.instance()
  getter(:compactor, default: Persist.Compactor.Presto)

  @type init_opts :: [
          load: Load.t()
        ]

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(init_opts) do
    server_opts = Keyword.take(init_opts, [:name])
    GenServer.start_link(__MODULE__, init_opts, server_opts)
  end

  @impl GenServer
  def init(init_opts) do
    load = Keyword.fetch!(init_opts, :load)
    {:ok, %{}, {:continue, {:compact, load}}}
  end

  @impl GenServer
  def handle_continue({:compact, load}, state) do
    with {:error, reason} <- Presto.Table.compact(load.destination) do
      Logger.warn(
        "#{__MODULE__}: Unable to complete compaction for #{load.dataset_id}__#{load.subset_id}: #{
          inspect(reason)
        }"
      )
    end

    Events.send_compact_end(@instance, __MODULE__, load)
    {:stop, :normal, state}
  end
end
