defmodule Gather.Extraction.SourceHandler do
  @moduledoc """
  Callbacks for handling data messages.

  See [Source.Handler](../../../../protocol_source/lib/source/handler.ex)
  for more.
  """
  use Source.Handler
  use Properties, otp_app: :service_gather
  use Annotated.Retry
  require Logger

  @max_tries get_config_value(:max_tries, default: 10)
  @initial_delay get_config_value(:initial_delay, default: 500)

  getter(:dlq, default: Dlq)
  getter(:app_name, required: true)

  @impl Source.Handler
  def handle_batch(batch, %{assigns: %{extract: extract}} = context) do
    messages =
      Decoder.decode(extract.decoder, batch)
      |> Enum.map(fn chunk -> lowercase_fields(chunk) end)
      |> normalize(extract)

    :ok = write_to_destination(extract.destination, context.assigns.destination_pid, messages)
  catch
    _, e ->
      warn_extract_failure(extract, e)
      send(context.assigns.pid, {:extract_failed, e})
  end

  @impl Source.Handler
  def send_to_dlq(dead_letters, _context) do
    dlq().write(dead_letters)
  end

  @impl Source.Handler
  def shutdown(context) do
    send(context.assigns.pid, :extract_complete)
    :ok
  end

  defp normalize(messages, extract) do
    %{good: good, bad: bad} =
      Enum.reduce(messages, %{good: [], bad: []}, fn message, acc ->
        case Dictionary.normalize(extract.dictionary, message) do
          {:ok, normalized_message} ->
            %{acc | good: [normalized_message | acc.good]}

          {:error, reason} ->
            dead_letter = to_dead_letter(extract, message, reason)
            %{acc | bad: [dead_letter | acc.bad]}
        end
      end)

    unless bad == [] do
      send_to_dlq(Enum.reverse(bad), %{})
    end

    Enum.reverse(good)
  end

  @retry with: exponential_backoff(@initial_delay) |> take(@max_tries)
  defp write_to_destination(destination, destination_pid, messages) do
    Destination.write(destination, destination_pid, messages)
  end

  defp lowercase_fields(%{} = map) do
    for {key, value} <- map, do: {String.downcase(key), lowercase_fields(value)}, into: %{}
  end

  defp lowercase_fields(list) when is_list(list) do
    Enum.map(list, &lowercase_fields/1)
  end

  defp lowercase_fields(v), do: v

  defp to_dead_letter(extract, og, reason) do
    DeadLetter.new(
      dataset_id: extract.dataset_id,
      subset_id: extract.subset_id,
      original_message: og,
      app_name: app_name(),
      reason: reason
    )
  end

  defp warn_extract_failure(extract, reason) do
    Logger.warn(fn ->
      "#{__MODULE__}: Failed with reason: #{inspect(reason)}, extract: #{inspect(extract)}"
    end)

    reason
  end
end
