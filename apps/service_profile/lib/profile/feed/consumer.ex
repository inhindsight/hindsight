defmodule Profile.Feed.Consumer do
  @moduledoc """
  Process for handling `GenStage` messages during profiling, sending a
  `profile_update` event.
  """
  use GenStage
  require Logger

  @type init_opts :: [
          dataset_id: String.t(),
          subset_id: String.t()
        ]

  @instance Profile.Application.instance()

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  @impl GenStage
  def init(opts) do
    Logger.debug(fn -> "#{__MODULE__}(#{inspect(self())}): init with #{inspect(opts)}" end)

    {:consumer,
     %{
       dataset_id: Keyword.fetch!(opts, :dataset_id),
       subset_id: Keyword.fetch!(opts, :subset_id)
     }}
  end

  @impl GenStage
  def handle_events(events, _from, state) do
    Logger.debug(fn -> "#{__MODULE__}(#{inspect(self())}): received events #{inspect(events)}" end)

    events
    |> Enum.map(fn event ->
      Profile.Update.new!(
        dataset_id: state.dataset_id,
        subset_id: state.subset_id,
        stats: event
      )
    end)
    |> Enum.each(fn update ->
      Events.send_profile_update(@instance, "service_profile", update)
    end)

    {:noreply, [], state}
  end
end
