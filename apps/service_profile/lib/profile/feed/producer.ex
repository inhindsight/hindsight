defmodule Profile.Feed.Producer do
  use GenStage
  use Properties, otp_app: :service_profile
  require Logger

  getter(:endpoints, required: true)

  defmodule Handler do
    use Elsa.Consumer.MessageHandler

    def handle_messages(messages, %{producer: producer} = state) do
      Logger.debug(fn -> "#{__MODULE__}(#{inspect(self())}): received #{inspect(messages)}" end)
      Profile.Feed.Producer.add_events(producer, messages)
      {:ack, state}
    end
  end

  def add_events(server, events, timeout \\ 5_000) do
    GenStage.call(server, {:events, events}, timeout)
  end

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    Logger.debug(fn -> "#{__MODULE__}(#{inspect(self())}): init with #{inspect(opts)}" end)
    Process.flag(:trap_exit, true)

    extract = Keyword.fetch!(opts, :extract)
    send(self(), {:init, extract})

    {:producer,
     %{
       elsa_sup: nil,
       queue: :queue.new(),
       demand: 0
     }}
  end

  def handle_call({:events, events}, _from, %{queue: queue} = state) do
    Logger.debug(fn -> "#{__MODULE__}: receiving events #{inspect(events)}" end)

    queue = Enum.reduce(events, queue, fn event, q ->
      update_in(event, [Access.key(:value)], fn value -> Jason.decode!(value) end)
      |> :queue.in(q)
    end)

    {new_state, events} = dispatch_events(%{state | queue: queue}, [])
    {:reply, :ok, events, new_state}
  end

  def handle_demand(incoming_demand, %{demand: pending_demand} = state) do
    {new_state, events} = dispatch_events(%{state | demand: pending_demand + incoming_demand}, [])
    {:noreply, events, new_state}
  end

  def handle_info({:init, extract}, state) do
    ensure_topic(extract)

    {:ok, elsa_sup} =
      Elsa.Supervisor.start_link(
        endpoints: endpoints(),
        connection: :"feed_#{extract.destination}",
        group_consumer: [
          group: "profile-#{extract.destination}",
          topics: [extract.destination],
          handler: Handler,
          handler_init_args: %{producer: self()},
          config: [
            begin_offset: :earliest,
            offset_reset_policy: :earliest,
            prefetch_count: 0,
            prefetch_bytes: 2_097_152
          ]
        ]
      )

    Logger.debug(fn -> "#{__MODULE__}(#{inspect(self())}): started elsa : #{inspect(elsa_sup)}" end)

    {:noreply, [], %{state | elsa_sup: elsa_sup}}
  end

  def handle_info({:EXIT, pid, reason} = message, %{elsa_sup: pid} = state) do
    Logger.debug(fn -> "#{__MODULE__}(#{inspect(self())}): received #{inspect(message)}" end)
    {:stop, reason, state}
  end

  def handle_info(message, state) do
    Logger.debug(fn -> "#{__MODULE__}(#{inspect(self())}): Unknown message #{inspect(message)}" end)
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

  defp ensure_topic(extract) do
    unless Elsa.topic?(endpoints(), extract.destination) do
      Elsa.create_topic(endpoints(), extract.destination, create_opts(extract.config))
    end
  end

  defp create_opts(config) do
    case get_in(config, ["kafka", "partitions"]) do
      nil -> []
      partitions -> [partitions: partitions]
    end
  end
end
