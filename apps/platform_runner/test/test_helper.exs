ExUnit.start(seed: 0)

defmodule TestHelper.Socket do
  use WebSockex

  def join(args) do
    pid = Keyword.fetch!(args, :caller)
    topic = Keyword.fetch!(args, :topic)

    {:ok, ws} = WebSockex.start("ws://localhost:4000/socket/websocket", __MODULE__, %{pid: pid})

    msg = %{
      topic: "broadcast:#{topic}",
      event: "phx_join",
      payload: %{},
      ref: 1
    }

    WebSockex.send_frame(ws, {:text, Jason.encode!(msg)})
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

  def handle_frame(frame, state) do
    IO.inspect(frame, label: "HEY")
    {:ok, state}
  end
end
