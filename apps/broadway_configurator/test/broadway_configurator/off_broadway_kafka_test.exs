defmodule BroadwayConfigurator.OffBroadwayKafkaTest do
  use ExUnit.Case

  defmodule Example do
    use BroadwayConfigurator.OffBroadwayKafka

    def name(ctx) do
      Ok.ok(ctx.name)
    end

    def endpoints(ctx) do
      ctx.endpoints
    end

    def connection(ctx) do
      ctx.connection
    end

    def offset_reset_policy(ctx) do
      ctx.offset_reset_policy
    end

    def group(ctx) do
      ctx.group
    end

    def topics(ctx) do
      ctx.topics
    end
  end

  test "something, something, obk" do
    context = %{
      name: :name,
      endpoints: :endpoints,
      connection: :connection,
      offset_reset_policy: :offset_reset_policy,
      group: :group,
      topics: :topics
    }

    assert Example.configure([], context) ==
             {:ok,
              [
                name: :name,
                producer: [
                  module:
                    {OffBroadway.Kafka.Producer,
                     [
                       endpoints: :endpoints,
                       connection: :connection,
                       group_consumer: [
                         group: :group,
                         topics: :topics,
                         config: [
                           begin_offset: :earliest,
                           offset_reset_policy: :offset_reset_policy,
                           prefetch_count: 0,
                           prefetch_bytes: 2_097_152
                         ]
                       ]
                     ]}
                ],
                processors: [],
                batchers: [],
                context: context
              ]}
  end
end
