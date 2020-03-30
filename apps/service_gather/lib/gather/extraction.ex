defmodule Gather.Extraction do
  import Events
  use GenServer, restart: :transient
  require Logger
  use Properties, otp_app: :service_gather
  use Annotated.Retry

  @max_tries get_config_value(:max_tries, default: 10)
  @initial_delay get_config_value(:initial_delay, default: 500)
  getter(:dlq, default: Dlq)
  getter(:app_name, required: true)

  def start_link(args) do
    server_opts = Keyword.take(args, [:name])
    GenServer.start_link(__MODULE__, args, server_opts)
  end

  @impl GenServer
  def init(args) do
    Process.flag(:trap_exit, true)
    {:ok, Map.new(args), {:continue, :extract}}
  end

  @dialyzer {:nowarn_function, handle_continue: 2}
  @impl GenServer
  def handle_continue(:extract, %{extract: extract} = state) do
    Logger.debug(fn -> "#{__MODULE__}: Started extraction: #{inspect(extract)}" end)

    case extract(extract) do
      {:ok, _topic} ->
        Logger.debug(fn -> "#{__MODULE__}: Extraction Completed: #{inspect(extract)}" end)
        Brook.Event.send(Gather.Application.instance(), extract_end(), "gather", extract)
        {:stop, :normal, state}

      {:error, reason} ->
        Logger.warn("#{__MODULE__}: Extraction Stopping: #{inspect(extract)}")
        {:stop, reason, state}
    end
  end

  @retry with: exponential_backoff(@initial_delay) |> take(@max_tries)
  defp extract(extract) do
    with {:ok, topic} <- start_destination(extract),
         :ok <- do_extract(topic, extract) do
      {:ok, topic}
    end
  end

  defp start_destination(extract) do
    Destination.start_link(
      extract.destination,
      Destination.Context.new!(
        app_name: app_name(),
        dataset_id: extract.dataset_id,
        subset_id: extract.subset_id,
        dictionary: extract.dictionary
      )
    )
  end

  defp do_extract(topic, extract) do
    Gather.Extraction.SourceStream.stream(extract)
    |> decode(extract)
    |> Ok.each(fn chunk ->
      messages =
        Enum.map(chunk, &lowercase_fields/1)
        |> normalize(extract)

      Destination.write(topic, messages)
    end)
  rescue
    e ->
      warn_extract_failure(extract, e)
      {:error, e}
  after
    Destination.stop(topic)
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

  defp decode(stream, extract) do
    Decoder.decode(extract.decoder, stream)
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

  defp warn_extract_failure(extract, reason) do
    Logger.warn(fn ->
      "#{__MODULE__}: Failed with reason: #{inspect(reason)}, extract: #{inspect(extract)}"
    end)

    reason
  end

  defp lowercase_fields(%{} = map) do
    for {key, value} <- map, do: {String.downcase(key), lowercase_fields(value)}, into: %{}
  end

  defp lowercase_fields(list) when is_list(list) do
    Enum.map(list, &lowercase_fields/1)
  end

  defp lowercase_fields(v), do: v
end
