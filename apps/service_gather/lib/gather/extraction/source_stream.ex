defmodule Gather.Extraction.SourceStream do
  defmodule SourceHandler do
    @moduledoc """
    Callbacks for handling data messages.

    See [Source.Handler](../../../../protocol_source/lib/source/handler.ex)
    for more.
    """
    use Source.Handler
    use Properties, otp_app: :service_gather

    getter(:dlq, default: Dlq)

    def handle_batch(batch, context) do
      send(context.assigns.pid, {:source_batch, batch})
      :ok
    end

    def send_to_dlq(dead_letters, _context) do
      dlq().write(dead_letters)
    end
  end

  def stream(extract) do
    Stream.resource(
      fn -> start_source(extract) end,
      fn {source, pid} ->
        receive do
          {:source_batch, batch} ->
            {[batch], {source, pid}}

          {:EXIT, ^pid, _reason} ->
            {:halt, {source, pid}}
        end
      end,
      fn _ -> :ok end
    )
  end

  defp start_source(extract) do
    {:ok, source_pid} = Source.start_link(extract.source, source_context(extract))
    {extract.source, source_pid}
  end

  defp source_context(extract) do
    Source.Context.new!(
      dictionary: extract.dictionary,
      handler: SourceHandler,
      app_name: :service_gather,
      dataset_id: extract.dataset_id,
      subset_id: extract.subset_id,
      decode_json: false,
      assigns: %{
        pid: self()
      }
    )
  end
end
