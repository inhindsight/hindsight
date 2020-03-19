defmodule Profile.Feed do
  use Supervisor

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
       reducers: determine_reducers(extract.dictionary, [], [Access.key(:value)])}
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
      find_temporal_range(reducers, dictionary, path)
      |> find_bounding_box(dictionary, path)

    dictionaries =
      Enum.filter(dictionary, fn %type{} -> type == Dictionary.Type.Map end)
      |> Enum.map(fn map -> {map.dictionary, path ++ [map.name]} end)

    determine_reducers(dictionaries, reducers)
  end

  defp find_bounding_box(reducers, dictionary, path) do
    longitude = Enum.find(dictionary, fn %type{} -> type == Dictionary.Type.Longitude end)
    latitude = Enum.find(dictionary, fn %type{} -> type == Dictionary.Type.Latitude end)

    case {longitude, latitude} do
      {long, lat} when long != nil and lat != nil ->
        reducer =
          Profile.Reducer.BoundingBox.new(
            longitude_path: path ++ [long.name],
            latitude_path: path ++ [lat.name]
          )

        add_to_reducers(reducers, reducer)

      _ ->
        reducers
    end
  end

  defp find_temporal_range(reducers, dictionary, path) do
    case Enum.find(dictionary, fn %type{} -> type == Dictionary.Type.Timestamp end) do
      nil ->
        reducers

      field ->
        reducer = Profile.Reducer.TemporalRange.new(path: path ++ [field.name])
        add_to_reducers(reducers, reducer)
    end
  end

  defp add_to_reducers(reducers, reducer) do
    case find_reducer(reducers, reducer) do
      nil -> reducers ++ [reducer]
      _ -> reducers
    end
  end

  defp find_reducer(reducers, %struct{}) do
    Enum.find(reducers, fn
      %^struct{} -> true
      _ -> false
    end)
  end
end
