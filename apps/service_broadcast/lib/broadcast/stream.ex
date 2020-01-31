defmodule Broadcast.Stream do
  use Supervisor

  @spec name(Load.Persist.t()) :: atom
  def name(load) do
    :"broadcast_stream_#{load.id}"
  end

  def start_link(init_arg) do
    load = Keyword.fetch!(init_arg, :load)
    Supervisor.start_link(__MODULE__, init_arg, name: name(load))
  end

  def init(init_arg) do
    load = Keyword.fetch!(init_arg, :load)

    cache_name = Broadcast.Cache.Registry.via(load.destination)

    children = [
      {Broadcast.Cache, name: cache_name},
      {Broadcast.Stream.Broadway, load: load}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
