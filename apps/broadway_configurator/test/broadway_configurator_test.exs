defmodule BroadwayConfiguratorTest do
  use ExUnit.Case

  defmodule Example do
    use BroadwayConfigurator.Default

    def name(ctx) do
      Ok.ok(ctx.name)
    end

    def configure_producer(_, ctx) do
      Ok.ok(ctx.producer)
    end

    def configure_processors(_, ctx) do
      Ok.ok(ctx.processors)
    end

    def configure_batchers(_, ctx) do
      Ok.ok(ctx.batchers)
    end
  end

  test "something, something configuration" do
    context = %{
      name: :name,
      producer: :producer,
      processors: :processors,
      batchers: :batchers
    }

    assert Example.configure([], context) ==
             {:ok,
              [
                name: :name,
                producer: :producer,
                processors: :processors,
                batchers: :batchers,
                context: context
              ]}
  end
end
