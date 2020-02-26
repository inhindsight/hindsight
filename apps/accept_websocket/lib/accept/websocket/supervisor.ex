defmodule Accept.Websocket.Supervisor do
  @moduledoc "TODO"
  use Supervisor
  require Logger

  def start_link(init_opts) do
    server_opts = Keyword.take(init_opts, [:name])

    Supervisor.start_link(__MODULE__, init_opts, server_opts)
  end

  @impl Supervisor
  def init(init_opts) do
    path = Keyword.fetch!(init_opts, :path)
    port = Keyword.fetch!(init_opts, :port)
    idle_timeout = Keyword.fetch!(init_opts, :idle_timeout)
    socket_args = Keyword.take(init_opts, [:timeout, :writer, :batch_size])

    [
      socket_child_spec(path, port, socket_args, idle_timeout)
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp socket_child_spec(path, port, socket_args, idle_timeout) do
    {Plug.Cowboy,
     [
       scheme: :http,
       plug: Accept.Websocket.Router,
       options: [
         port: port,
         dispatch: [{:_, [{"/#{path}", Accept.Websocket.Socket, socket_args}]}],
         protocol_options: [idle_timeout: idle_timeout]
       ]
     ]}
  end
end
