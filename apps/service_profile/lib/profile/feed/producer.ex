defmodule Profile.Feed.Producer do
  use GenStage
  use Properties, otp_app: :service_profile
  require Logger

  @type init_opts :: [
          extract: Extract.t()
        ]

  getter(:dlq, default: Dlq)

  defmodule Handler do
    @moduledoc """
    Callbacks for handling data messages.

    See [Source.Handler](../../../../protocol_source/lib/source/handler.ex)
    for more.
    """
    use Source.Handler

    def handle_batch(batch, context) do
      Logger.debug(fn -> "#{__MODULE__}(#{inspect(self())}): received #{inspect(batch)}" end)
      Profile.Feed.Producer.add_events(context.assigns.producer, batch)
      :ok
    end

    def send_to_dlq(dead_letters, context) do
      context.assigns.dlq.write(dead_letters)
    end
  end

  @spec add_events(GenServer.name(), list(), integer()) :: term
  def add_events(server, events, timeout \\ 5_000) do
    GenStage.call(server, {:events, events}, timeout)
  end

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  @impl GenStage
  def init(opts) do
    Logger.debug(fn -> "#{__MODULE__}(#{inspect(self())}): init with #{inspect(opts)}" end)
    Process.flag(:trap_exit, true)

    extract = Keyword.fetch!(opts, :extract)
    send(self(), {:init, extract})

    {:producer,
     %{
       source_pid: nil,
       queue: :queue.new(),
       demand: 0
     }}
  end

  @impl GenStage
  def handle_call({:events, events}, _from, %{queue: queue} = state) do
    Logger.debug(fn -> "#{__MODULE__}: receiving events #{inspect(events)}" end)

    queue =
      Enum.reduce(events, queue, fn event, q ->
        :queue.in(event, q)
      end)

    {new_state, events} = dispatch_events(%{state | queue: queue}, [])
    {:reply, :ok, events, new_state}
  end

  @impl GenStage
  def handle_demand(incoming_demand, %{demand: pending_demand} = state) do
    {new_state, events} = dispatch_events(%{state | demand: pending_demand + incoming_demand}, [])
    {:noreply, events, new_state}
  end

  @impl GenStage
  def handle_info({:init, extract}, state) do
    context =
      Source.Context.new!(
        dataset_id: extract.dataset_id,
        subset_id: extract.subset_id,
        app_name: :service_profile,
        dictionary: extract.dictionary,
        handler: Handler,
        assigns: %{
          producer: self(),
          dlq: dlq()
        }
      )

    {:ok, source_pid} = Source.start_link(extract.destination, context)

    Logger.debug(fn ->
      "#{__MODULE__}(#{inspect(self())}): started source : #{inspect(source_pid)}"
    end)

    {:noreply, [], %{state | source_pid: source_pid}}
  end

  @impl GenStage
  def handle_info({:EXIT, pid, reason} = message, %{elsa_sup: pid} = state) do
    Logger.debug(fn -> "#{__MODULE__}(#{inspect(self())}): received #{inspect(message)}" end)
    {:stop, reason, state}
  end

  @impl GenStage
  def handle_info(message, state) do
    Logger.debug(fn ->
      "#{__MODULE__}(#{inspect(self())}): Unknown message #{inspect(message)}"
    end)

    {:noreply, [], state}
  end

  defp dispatch_events(%{demand: 0} = state, events) do
    {state, Enum.reverse(events)}
  end

  defp dispatch_events(%{queue: queue, demand: demand} = state, events) do
    Logger.debug(fn -> "#{__MODULE__}: current state = #{inspect(state)}" end)

    case :queue.out(queue) do
      {{:value, event}, queue} ->
        dispatch_events(%{state | queue: queue, demand: demand - 1}, [event | events])

      {:empty, _queue} ->
        {state, Enum.reverse(events)}
    end
  end
end
