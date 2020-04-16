defmodule BroadcastWeb.Channel do
  @moduledoc false
  use BroadcastWeb, :channel
  require Logger

  @update_event "update"
  intercept [@update_event]

  def join("broadcast:" <> topic, _message, socket) do
    send(self(), {:after_join, topic})
    {:ok, socket}
  end

  def handle_in(_type, _message, socket) do
    {:noreply, socket}
  end

  def handle_info({:after_join, topic}, socket) do
    Broadcast.Cache.Registry.via(topic)
    |> Broadcast.Cache.get()
    |> Enum.each(&push(socket, @update_event, &1))

    {:noreply, socket}
  catch
    :exit, _ ->
      {:noreply, socket}
  end

  def handle_out(@update_event, payload, socket) do
    Logger.debug(fn -> "#{__MODULE__}: outbound message : #{inspect(payload)}" end)
    push(socket, @update_event, payload)
    {:noreply, socket}
  end
end
