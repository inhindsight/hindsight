defmodule Gather.Extraction.SourceStream do
  defmodule SourceHandler do
    @moduledoc """
    Callbacks for handling data messages.

    See [Source.Handler](../../../../protocol_source/lib/source/handler.ex)
    for more.
    """
    use Source.Handler
    use Properties, otp_app: :service_gather
    require Logger

    getter(:dlq, default: Dlq)
    getter(:app_name, required: true)

    @spec handle_batch(any, atom | %{assigns: atom | %{pid: any}}) :: :ok
    def handle_batch(batch, context) do
      extract = context.assigns.extract

      Decoder.decode(extract.decoder, batch)
      |> Ok.each(fn chunk ->
        messages =
          Enum.map(chunk, &lowercase_fields/1)
          |> normalize(extract)

        Destination.write(extract.destination, context.assigns.destination_pid, messages)
      end)
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
        dlq().write(Enum.reverse(bad))
      end

      Enum.reverse(good)
    end

    defp lowercase_fields(%{} = map) do
      for {key, value} <- map, do: {String.downcase(key), lowercase_fields(value)}, into: %{}
    end

    defp lowercase_fields(list) when is_list(list) do
      Enum.map(list, &lowercase_fields/1)
    end

    defp lowercase_fields(v), do: v

    def send_to_dlq(dead_letters, _context) do
      dlq().write(dead_letters)
    end

    defp to_dead_letter(extract, og, reason) do
      DeadLetter.new(
        dataset_id: extract.dataset_id,
        subset_id: extract.subset_id,
        original_message: og,
        app_name: app_name(),
        reason: reason
      )
    end
  end

  # def stream(extract) do
  #   Stream.resource(
  #     fn -> start_source(extract) end,
  #     fn {source, pid} ->
  #       receive do
  #         {:source_batch, batch} ->
  #           {[batch], {source, pid}}

  #         {:EXIT, ^pid, _reason} ->
  #           {:halt, {source, pid}}
  #       end
  #     end,
  #     fn _ -> :ok end
  #   )
  # end

  def start_source(extract, destination_pid) do
    {:ok, source_pid} =
      Source.start_link(extract.source, source_context(extract, destination_pid))

    {extract.source, source_pid}
  end

  defp source_context(extract, destination_pid) do
    Source.Context.new!(
      dictionary: extract.dictionary,
      handler: SourceHandler,
      app_name: :service_gather,
      dataset_id: extract.dataset_id,
      subset_id: extract.subset_id,
      decode_json: false,
      assigns: %{
        pid: self(),
        destination_pid: destination_pid,
        extract: extract
      }
    )
  end
end
