defmodule Gather.Extraction do
  use GenServer, restart: :transient
  require Logger
  use Properties, otp_app: :service_gather
  use Annotated.Retry

  alias Extract.Context
  alias Writer.DLQ.DeadLetter

  @max_tries get_config_value(:max_tries, default: 10)
  @initial_delay get_config_value(:initial_delay, default: 500)
  getter(:writer, default: Gather.Writer)
  getter(:dlq, default: Gather.DLQ)
  getter(:chunk_size, default: 1_000)
  getter(:app_name, required: true)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
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
      :ok ->
        Logger.debug("#{__MODULE__}: Extraction Completed: #{inspect(extract)}")
        Brook.Event.send(Gather.Application.instance(), "extract:end", "gather", extract)
        {:stop, :normal, state}

      {:error, reason} ->
        Logger.warn("#{__MODULE__}: Extraction Stopping: #{inspect(extract)}")
        {:stop, reason, state}
    end
  end

  @retry with: exponential_backoff(@initial_delay) |> take(@max_tries)
  defp extract(extract) do
    with {:ok, writer} <- writer().start_link(extract: extract) do
      do_extract(writer, extract)
    end
  end

  defp do_extract(writer, extract) do
    with {:ok, context} <- Extractor.execute(extract.steps),
         {:error, reason} <- write(writer, extract, context) do
      warn_extract_failure(extract, reason)
      {:error, reason}
    end
  rescue
    e -> {:error, e}
  after
    Process.exit(writer, :normal)
  end

  defp write(writer, extract, context) do
    writer_opts = [dataset_id: extract.dataset_id]

    Context.get_stream(context)
    |> Stream.chunk_every(chunk_size())
    |> Ok.each(fn chunk ->
      with data <- Enum.map(chunk, &Map.get(&1, :data)),
           normalized_messages <- normalize(extract, data),
           :ok <- writer().write(writer, normalized_messages, writer_opts) do
        Context.run_after_functions(context, chunk)
        :ok
      end
    end)
  end

  defp normalize(extract, messages) do
    %{good: good, bad: bad} =
      Enum.reduce(messages, %{good: [], bad: []}, fn message, acc ->
        case Dictionary.normalize(extract.dictionary, message) do
          {:ok, normalized_message} ->
            %{acc | good: [normalized_message | acc.good]}

          {:error, reason} ->
            dead_letter = to_dead_letter(extract.dataset_id, message, reason)
            %{acc | bad: [dead_letter | acc.bad]}
        end
      end)

    unless bad == [] do
      dlq().write(Enum.reverse(bad))
    end

    Enum.reverse(good)
  end

  defp to_dead_letter(dataset_id, og, reason) do
    DeadLetter.new(
      dataset_id: dataset_id,
      original_message: og,
      app_name: app_name(),
      reason: reason
    )
  end

  defp warn_extract_failure(extract, reason) do
    Logger.warn(
      "#{__MODULE__}: Failed with reason: #{inspect(reason)}, extract: #{inspect(extract)}"
    )
  end
end
