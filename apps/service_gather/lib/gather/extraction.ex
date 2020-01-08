defmodule Gather.Extraction do
  use GenServer, restart: :transient

  @config Application.get_env(:service_gather, __MODULE__, [])
  @writer Keyword.get(@config, :writer, Gather.Writer)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    {:ok, Map.new(args), {:continue, :extract}}
  end

  @impl GenServer
  def handle_continue(:extract, %{extract: extract} = state) do
    {:ok, writer} = @writer.start_link(extract: extract)
    extract(writer, extract)
    Process.exit(writer, :normal)
    {:stop, :normal, state}
  end

  defp extract(writer, %Extract{} = extract) do
    {:ok, stream} = Extract.Steps.execute(extract.steps)
    messages = Enum.to_list(stream)
    @writer.write(writer, messages)
  end
end
