defmodule Gather.Extraction do
  import Events
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
        Brook.Event.send(Gather.Application.instance(), extract_end(), "gather", extract)
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
    writer_opts = [extract: extract]

    Context.get_stream(context)
    |> Ok.each(fn chunk ->
      with data <- Enum.map(chunk, &Map.get(&1, :data)),
           lowercase_data <- Enum.map(data, &lowercase_fields/1),
           normalized_messages <- normalize(extract, lowercase_data),
           :ok <- writer().write(writer, normalized_messages, writer_opts) do
        Context.run_after_functions(context, chunk)
        :ok
      end
    end)
  catch
    _, reason ->
      Context.run_error_functions(context)
      {:error, reason}
  end

  defp normalize(extract, messages) do
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
    Logger.warn(
      "#{__MODULE__}: Failed with reason: #{inspect(reason)}, extract: #{inspect(extract)}"
    )
  end

  defp lowercase_fields(%{} = map) do
    for {key, value} <- map, do: {String.downcase(key), lowercase_fields(value)}, into: %{}
  end

  defp lowercase_fields(list) when is_list(list) do
    Enum.map(list, &lowercase_fields/1)
  end

  defp lowercase_fields(v), do: v
end
