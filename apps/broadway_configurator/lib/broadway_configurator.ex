defmodule BroadwayConfigurator do
  @callback configure(config :: keyword, context :: term) :: {:ok, keyword} | {:error, term}
end

defmodule BroadwayConfigurator.Default do
  @callback name(context :: term) :: {:ok, atom} | {:error, term}
  @callback configure_producer(config :: keyword, context :: term) :: {:ok, keyword} | {:error, term}
  @callback configure_processors(config :: keyword, context :: term) :: {:ok, keyword} | {:error, term}
  @callback configure_batchers(config :: keyword, context :: term) :: {:ok, keyword} | {:error, term}

  defmacro __using__(_opts) do
    quote do
      @behaviour BroadwayConfigurator
      @behaviour BroadwayConfigurator.Default

      def configure(config, context) do
        with {:ok, name} <- name(context),
             {:ok, producer} <- configure_producer(Keyword.get(config, :producer, []), context),
             {:ok, processors} <- configure_processors(Keyword.get(config, :processors, []), context),
             {:ok, batchers} <- configure_batchers(Keyword.get(config, :batchers, []), context) do
          {:ok,
           [
             name: name,
             producer: producer,
             processors: processors,
             batchers: batchers,
             context: context
           ]}
        end
      end

      def configure_producer(producer, _), do: {:ok, producer}
      def configure_processors(processors, _), do: {:ok, processors}
      def configure_batchers(batchers, _), do: {:ok, batchers}

      defoverridable BroadwayConfigurator
      defoverridable BroadwayConfigurator.Default
    end
  end
end

defmodule BroadwayConfigurator.Dummy do
  use BroadwayConfigurator.Default

  def name(_) do
    Ok.ok(:broadway_dummy)
  end

  def configure_producer(_, _) do
    [
      module: {Broadway.DummyProducer, []},
      stages: 1
    ]
    |> Ok.ok()
  end

  def configure_processors(_, _) do
    [
      default: [
        stages: 1
      ]
    ]
    |> Ok.ok()
  end

  def configure_batchers(_, _) do
    [
      default: [
        stages: 1,
        batch_size: 100
      ]
    ]
    |> Ok.ok()
  end
end

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
