defmodule Broadcast.Stream.SourceHandler do
  use Source.Handler
  use Properties, otp_app: :service_broadcast
  require Logger

  alias BroadcastWeb.Endpoint

  getter(:dlq, default: Dlq)

  def handle_message(message, context) do
    with {:ok, transformed_value} <- context.assigns.transformer.(message) do
      load = context.assigns.load

      Logger.debug(fn ->
        "#{__MODULE__}: Broadcasting to broadcast:#{load.destination.name}: #{
          inspect(transformed_value)
        }"
      end)

      Endpoint.broadcast!("broadcast:#{load.destination.name}", "update", transformed_value)
      Ok.ok(transformed_value)
    end
  end

  def handle_batch(batch, context) do
    Logger.debug(fn -> "#{__MODULE__} handle_batch - #{inspect(context)} - #{inspect(batch)}" end)

    unless context.assigns.load.destination.cache == 0 do
      Broadcast.Cache.add(context.assigns.cache, batch)
    end

    :ok
  end

  def send_to_dlq(dead_letters, _context) do
    dlq().write(dead_letters)
    :ok
  end
end
