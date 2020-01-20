defmodule Kafka.Subscribe do
  @enforce_keys [:endpoints, :topic]
  defstruct [:endpoints, :topic]

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Steps.Context
    alias Kafka.Subscribe.Acknowledger

    def execute(%{endpoints: endpoints, topic: topic}, context) do
      ensure_topic(endpoints, topic)
      connection = :"kafka_subscribe_#{topic}"

      {:ok, acknowledger} = Kafka.Subscribe.Acknowledger.start_link(connection: connection)

      source = fn _opts ->
        Stream.resource(
          initialize(endpoints, topic, connection, acknowledger),
          &receive_messages/1,
          &shutdown/1
        )
      end

      context
      |> register_after_function(&acknowledge_values(acknowledger, &1))
      |> set_source(source)
      |> Ok.ok()
    end

    defp acknowledge_values(acknowledger, values) do
      Acknowledger.ack(acknowledger, values)
    end

    defp receive_messages(%{acknowledger: acknowledger} = acc) do
      receive do
        {:kafka_subscribe, messages} ->
          Acknowledger.cache(acknowledger, messages)
          {messages, acc}
      end
    end

    defp ensure_topic(endpoints, topic) do
      unless Elsa.topic?(endpoints, topic) do
        Elsa.create_topic(endpoints, topic)
      end
    end

    defp initialize(endpoints, topic, connection, acknowledger) do
      fn ->
        {:ok, elsa} =
          Elsa.Supervisor.start_link(
            connection: connection,
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

        %{elsa_supervisor: elsa, acknowledger: acknowledger}
      end
    end

    defp shutdown(%{elsa_supervisor: elsa, acknowledger: acknowledger} = acc) do
      Process.exit(elsa, :normal)
      Process.exit(acknowledger, :normal)
      acc
    end
  end
end

defmodule Kafka.Subscribe.Handler do
  use Elsa.Consumer.MessageHandler

  def handle_messages(messages, state) do
    send(state.pid, {:kafka_subscribe, messages})
    {:no_ack, state}
  end
end
