defmodule Profile.Feed.Flow do
  use Flow
  use Properties, otp_app: :service_profile

  alias Profile.Feed.Flow.Storage

  getter(:window_limit, default: 5)
  getter(:window_unit, default: :minute)

  @type init_opts :: [
          name: GenServer.name(),
          dataset_id: String.t(),
          subset_id: String.t(),
          from_specs: list(Supervisor.child_spec()),
          into_specs: list(Supervisor.child_spec()),
          reducers: %{required(module) => term}
        ]

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(opts) do
    flow_opts = Keyword.take(opts, [:name])

    dataset_id = Keyword.fetch!(opts, :dataset_id)
    subset_id = Keyword.fetch!(opts, :subset_id)
    from_specs = Keyword.fetch!(opts, :from_specs)
    into_specs = Keyword.fetch!(opts, :into_specs) |> Enum.map(fn consumer -> {consumer, []} end)
    reducers = Keyword.fetch!(opts, :reducers)

    window = Flow.Window.periodic(window_limit(), window_unit())

    {:ok, stats} = Profile.Feed.Store.get_stats(dataset_id, subset_id)
    reducers = Enum.map(reducers, &Profile.Reducer.init(&1, stats))
    {:ok, storage} = Storage.start_link(reducers: reducers)

    from_specs
    |> Flow.from_specs()
    |> Flow.partition(window: window, stages: 1)
    |> Flow.reduce(fn -> Storage.get(storage) end, &reduce/2)
    |> Flow.on_trigger(fn acc ->
      case Storage.merge(storage, acc) do
        [] ->
          {[], %{}}

        changed_reducers ->
          event =
            changed_reducers
            |> Enum.flat_map(&Profile.Reducer.to_event_fields/1)
            |> Map.new()

          {[event], %{}}
      end
    end)
    |> Flow.into_specs(into_specs, flow_opts)
  end

  defp reduce(event, accumulator) do
    accumulator
    |> Enum.map(fn reducer ->
      Profile.Reducer.reduce(reducer, event)
    end)
  end
end
