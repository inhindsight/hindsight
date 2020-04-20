defmodule PlatformRunner.BroadcastClient do
  @moduledoc """
  WebSocket client for testing `service_broadcast` in e2e tests.
  """
  use WebSockex

  @url "ws://localhost:4000/socket/websocket"

  def join(args) do
    with pid <- Keyword.fetch!(args, :caller),
         topic <- Keyword.fetch!(args, :topic),
         {:ok, ws} <- WebSockex.start(@url, __MODULE__, %{pid: pid}),
         msg <- %{topic: "broadcast:#{topic}", event: "phx_join", payload: %{}, ref: 1},
         :ok <- WebSockex.send_frame(ws, {:text, Jason.encode!(msg)}) do
      {:ok, ws}
    end
  end

  def kill(ws) do
    Process.exit(ws, :kill)
  end

  def handle_connect(_, state) do
    {:ok, state}
  end

  def handle_frame({:text, %{event: "phx_join"} = msg}, state) do
    {:reply, {:text, Jason.encode!(msg)}, state}
  end

  def handle_frame({:text, msg}, state) do
    message = Jason.decode!(msg)
    send(state.pid, Map.get(message, "payload"))

    {:ok, state}
  end

  def handle_frame(_, state) do
    {:ok, state}
  end

  def terminate(_, state) do
    {:ok, state}
  end
end
