defmodule Accept.Websocket.Socket do
  @moduledoc "TODO"
  use Accept.Socket
  require Logger
  @behaviour :cowboy_websocket

  @impl :cowboy_websocket
  def init(req, opts) do
    {:cowboy_websocket, req, opts}
  end

  @impl :cowboy_websocket
  def websocket_init(init_opts) do
    state = %{
      batch_size: Keyword.fetch!(init_opts, :batch_size),
      writer: Keyword.fetch!(init_opts, :writer),
      hibernate: Keyword.get(init_opts, :hibernate, false),
      timeout: Keyword.fetch!(init_opts, :timeout),
      queue: []
    }

    :timer.send_interval(state.timeout, :msg_timeout)

    socket_return({:ok, state})
  end

  @impl :cowboy_websocket
  def websocket_handle({type, message}, %{queue: queue, batch_size: size} = state)
      when batch_reached?(queue, size) and type in [:text, :binary] do
    process_messages([message | queue], state.writer)

    socket_return({:reply, {:text, "received"}, %{state | queue: []}})
  end

  @impl :cowboy_websocket
  def websocket_handle({type, message}, state) when type in [:text, :binary] do
    socket_return({:reply, {:text, "queued"}, %{state | queue: [message | state.queue]}})
  end

  @impl :cowboy_websocket
  def websocket_handle(:ping, state) do
    {:reply, :pong, state}
  end

  @impl :cowboy_websocket
  def websocket_info(:msg_timeout, %{queue: queue} = state) when length(queue) > 0 do
    process_messages(queue, state.writer)

    socket_return({:ok, %{state | queue: []}})
  end

  @impl :cowboy_websocket
  def websocket_info(:msg_timeout, state) do
    socket_return({:ok, state})
  end

  @impl :cowboy_websocket
  def terminate(_reason, _req, %{queue: queue} = state) when length(queue) > 0 do
    process_messages(queue, state.writer)

    :ok
  end

  @impl :cowboy_websocket
  def terminate(_reason, _req, _state) do
    :ok
  end

  defp process_messages(messages, writer) do
    messages
    |> Enum.reverse()
    |> handle_messages(writer)
  end

  defp socket_return(response) do
    response
    |> Tuple.to_list()
    |> List.last()
    |> Map.get(:hibernate)
    |> case do
      true -> Tuple.append(response, :hibernate)
      false -> response
    end
  end
end
