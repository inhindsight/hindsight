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
