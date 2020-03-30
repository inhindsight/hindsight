defmodule Profile.Feed do
  use Supervisor

  @type init_opts :: [
          name: GenServer.name(),
          extract: Extract.t()
        ]

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(opts) do
    server_opts = Keyword.take(opts, [:name])
    Supervisor.start_link(__MODULE__, opts, server_opts)
  end

  @impl true
  def init(opts) do
    extract = Keyword.fetch!(opts, :extract)

    children = [
      {Profile.Feed.Flow,
       dataset_id: extract.dataset_id,
       subset_id: extract.subset_id,
       from_specs: [
         {Profile.Feed.Producer, extract: extract}
       ],
       into_specs: [
         {Profile.Feed.Consumer, dataset_id: extract.dataset_id, subset_id: extract.subset_id}
       ],
       reducers: determine_reducers(extract.dictionary, [], [])}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def determine_reducers([], reducers), do: reducers

  def determine_reducers([{_, _} | _] = dictionaries, reducers) do
    Enum.reduce(dictionaries, reducers, fn {dictionary, path}, acc ->
      determine_reducers(dictionary, acc, path)
    end)
  end

  def determine_reducers(dictionary, reducers, path) do
    reducers =
      [Profile.Reducer.TemporalRange, Profile.Reducer.BoundingBox]
      |> Enum.reduce(reducers, &maybe_add_reducers(&2, &1, dictionary, path))
      |> List.flatten()

    dictionaries =
      Enum.filter(dictionary, fn %type{} -> type == Dictionary.Type.Map end)
      |> Enum.map(fn map -> {map.dictionary, path ++ [map.name]} end)

    determine_reducers(dictionaries, reducers)
  end

  defp maybe_add_reducers(reducers, reducer, dictionary, path) do
    unless includes_reducer?(reducers, reducer) do
      reducers ++ create_reducers(reducer, dictionary, path)
    else
      reducers
    end
  end

  defp create_reducers(Profile.Reducer.BoundingBox, dictionary, path) do
    longitude = Enum.find(dictionary, fn %type{} -> type == Dictionary.Type.Longitude end)
    latitude = Enum.find(dictionary, fn %type{} -> type == Dictionary.Type.Latitude end)

    case {longitude, latitude} do
      {long, lat} when long != nil and lat != nil ->
        Profile.Reducer.BoundingBox.new(
          longitude_path: path ++ [long.name],
          latitude_path: path ++ [lat.name]
        )
        |> List.wrap()

      _ ->
        []
    end
  end

  defp create_reducers(Profile.Reducer.TemporalRange, dictionary, path) do
    case Enum.find(dictionary, fn %type{} -> type == Dictionary.Type.Timestamp end) do
      nil ->
        []

      field ->
        [Profile.Reducer.TemporalRange.new(path: path ++ [field.name])]
    end
  end

  defp includes_reducer?(reducers, reducer) do
    Enum.any?(reducers, fn %struct{} -> struct == reducer end)
  end
end
