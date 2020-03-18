defmodule Profile.Feed.Consumer do
  use GenStage
  require Logger

  @instance Profile.Application.instance()

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    Logger.debug(fn -> "#{__MODULE__}(#{inspect(self())}): init with #{inspect(opts)}" end)
    {:consumer,
     %{
       dataset_id: Keyword.fetch!(opts, :dataset_id),
       subset_id: Keyword.fetch!(opts, :subset_id)
     }}
  end

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
