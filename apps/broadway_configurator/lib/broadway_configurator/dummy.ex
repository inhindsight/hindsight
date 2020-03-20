defmodule BroadwayConfigurator.Dummy do
  use BroadwayConfigurator.Default

  def name(_) do
    Ok.ok(:broadway_dummy)
  end

  def configure_producer(_, _) do
    [
      module: {Broadway.DummyProducer, []},
      concurrency: 1
    ]
    |> Ok.ok()
  end

  def configure_processors(_, _) do
    [
      default: [
        concurrency: 1
      ]
    ]
    |> Ok.ok()
  end

  def configure_batchers(_, _) do
    [
      default: [
        concurrency: 1,
        batch_size: 100
      ]
    ]
    |> Ok.ok()
  end
end
