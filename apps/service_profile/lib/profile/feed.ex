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
       reducers: [
         Profile.Reducer.TemporalRange.new(path: [Access.key(:value), "ts"])
       ]
      }
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
