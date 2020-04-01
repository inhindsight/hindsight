defmodule Persist.Load.SourceHandler do
  use Source.Handler
  use Properties, otp_app: :service_persist
  require Logger

  getter(:dlq, default: Dlq)

  def handle_message(message, context) do
    Logger.debug(fn -> "#{__MODULE__}: handling message #{inspect(message)}" end)

    context.assigns.transformer.(message)
  end

  def handle_batch(batch, context) do
    Destination.write(context.assigns.destination, batch)
    :ok
  end

  def send_to_dlq(dead_letters, _context) do
    dlq().write(dead_letters)
    :ok
  end
end
