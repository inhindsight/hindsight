defmodule Gather.Extraction do
  use GenServer, restart: :transient
  use Retry
  require Logger

  @config Application.get_env(:service_gather, __MODULE__, [])

  @writer Keyword.get(@config, :writer, Gather.Writer)
  @chunk_size Keyword.get(@config, :chunk_size, 100)
  @max_tries Keyword.get(@config, :max_tries, 10)
  @initial_delay Keyword.get(@config, :initial_delay, 500)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    {:ok, Map.new(args), {:continue, :extract}}
  end

  @dialyzer {:nowarn_function, handle_continue: 2}
  @impl GenServer
  def handle_continue(:extract, %{extract: extract} = state) do
    retry with: exponential_backoff(@initial_delay) |> Stream.take(@max_tries) do
      with {:ok, writer} <- @writer.start_link(extract: extract) do
        extract(writer, extract)
      end
    after
      :ok -> {:stop, :normal, state}
    else
      {:error, reason} -> {:stop, reason, state}
    end
  end

  defp extract(writer, extract) do
    with {:ok, stream} <- Extract.Steps.execute(extract.steps),
         {:error, reason} <- write(writer, stream) do
      warn_extract_failure(extract, reason)
      {:error, reason}
    end
  rescue
    e -> {:error, e}
  after
    Process.exit(writer, :normal)
  end

  defp write(writer, stream) do
    stream
    |> Stream.chunk_every(@chunk_size)
    |> Ok.each(&@writer.write(writer, &1))
  end

  defp warn_extract_failure(extract, reason) do
    Logger.warn(
      "#{__MODULE__}: Failed with reason: #{inspect(reason)}, extract: #{inspect(extract)}"
    )
  end
end
