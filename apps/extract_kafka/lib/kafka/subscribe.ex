defmodule Kafka.Subscribe do
  @enforce_keys [:endpoints, :topic]
  defstruct [:endpoints, :topic]

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Steps.Context

    def execute(%{endpoints: endpoints, topic: topic}, context) do
      ensure_topic(endpoints, topic)

      source = fn _opts ->
        Stream.resource(
          initialize_elsa(endpoints, topic),
          &receive_messages/1,
          &stop_elsa/1
        )
      end

      context
      |> set_source(source)
      |> Ok.ok()
    end

    defp receive_messages(acc) do
      receive do
        {:kafka_subscribe, messages} ->
          # TODO possibly write value and meta data to ets table
          {messages, acc}
      end
    end

    defp ensure_topic(endpoints, topic) do
      unless Elsa.topic?(endpoints, topic) do
        Elsa.create_topic(endpoints, topic)
      end
    end

    defp initialize_elsa(endpoints, topic) do
      fn ->
        {:ok, pid} =
          Elsa.Supervisor.start_link(
            connection: :"kafka_subscribe_#{topic}",
            endpoints: endpoints,
            group_consumer: [
              group: "kafka_subscribe_#{topic}",
              topics: [topic],
              handler: Kafka.Subscribe.Handler,
              handler_init_args: %{pid: self()},
              config: [
                begin_offset: :earliest,
                offset_reset_policy: :reset_to_earliest,
                prefetch_count: 0,
                prefetch_bytes: 1_000_000
              ]
            ]
          )

        %{elsa_supervisor: pid}
      end
    end

    defp stop_elsa(%{elsa_supervisor: pid} = acc) do
      Process.exit(pid, :normal)
      acc
    end
  end
end

defmodule Kafka.Subscribe.Handler do
  use Elsa.Consumer.MessageHandler

  def handle_messages(messages, state) do
    send(state.pid, {:kafka_subscribe, messages})
    {:ack, state}
  end
end
