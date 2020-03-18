defmodule Profile.Feed.Producer do
  use GenStage
  use Properties, otp_app: :service_profile

  getter(:endpoints, required: true)

  defmodule Handler do
    use Elsa.Consumer.MessageHandler

    def handle_messages(messages, producer) do
      Profile.Feed.Producer.add_events(producer, messages)
      :ack
    end
  end

  def add_events(server, events, timeout \\ 5_000) do
    GenStage.call(server, {:events, events}, timeout)
  end

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    Process.flag(:trap_exit, true)

    extract = Keyword.fetch!(opts, :extract)

    {:ok, elsa_sup} = Elsa.Supervisor.start_link(
      endpoints: endpoints(),
      connection: :"feed_#{extract.destination}",
      group_consumer: [
        group: "profile-#{extract.destination}",
        topics: [extract.destination],
        handler: Handler,
        handler_init_args: self(),
        config: [
          offset_reset_policy: :earliest,
          prefetch_count: 0,
          prefetch_bytes: 2,097,152
        ]
      ]
    )

    {:producer, %{
        elsa_sup: elsa_sup,
        queue: :queue.new(),
        demand: 0
     }}
  end

  def handle_call({:events, events}, _from, %{queue: queue} = state) do
    Enum.reduce(events, queue, fn event, q -> :queue.in(event, q) end)
    {new_state, events} = dispatch_events(%{state | queue: queue}, [])
    {:reply, :ok, events, new_state}
  end

  def handle_demand(incoming_demand, %{demand: pending_demand} = state) do
    {new_state, events} = dispatch_events(%{demand: pending_demand + incoming_demand}, [])
    {:noreply, [], state}
  end

  def handle_info({:EXIT, _, _}) do
    {:stop, reason}
  end

  defp dispatch_events(%{demand: 0} = state, events) do
    {state, Enum.reverse(events)}
  end

  defp dispatch_events(%{queue: queue, demand: demand} = state, events)
    case :queue.out(queue) do
      {{:value, event}, queue} -> dispatch_events(%{state | queue: queue, demand: demand - 1}, [event | events])
      {:empty, queue} -> {state, Enum.reverse(events)}
    end
  end

end
