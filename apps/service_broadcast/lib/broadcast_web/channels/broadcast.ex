defmodule BroadcastWeb.Channel do
  use BroadcastWeb, :channel

  @update_event "update"

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
    |> Enum.map(&push(socket, @update_event, &1))

    {:noreply, socket}
  catch
    :exit, _ ->
      {:noreply, socket}
  end
end
