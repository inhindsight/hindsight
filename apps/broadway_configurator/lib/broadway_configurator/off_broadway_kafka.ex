defmodule BroadwayConfigurator.OffBroadwayKafka do
  @callback endpoints(term) :: keyword
  @callback connection(term) :: atom
  @callback offset_reset_policy(term) :: atom
  @callback group(term) :: String.t()
  @callback topics(term) :: list(String.t())

  defmacro __using__(_opts) do
    quote do
      use BroadwayConfigurator.Default
      @behaviour BroadwayConfigurator.OffBroadwayKafka

      def configure_producer(producer, context) do
        module =
          {OffBroadway.Kafka.Producer,
           [
             endpoints: endpoints(context),
             connection: connection(context),
             group_consumer: [
               group: group(context),
               topics: topics(context),
               config: [
                 begin_offset: :earliest,
                 offset_reset_policy: offset_reset_policy(context),
                 prefetch_count: 0,
                 prefetch_bytes: 2_097_152
               ]
             ]
           ]}

        producer
        |> Keyword.put(:module, module)
        |> Ok.ok()
      end
    end
  end
end
