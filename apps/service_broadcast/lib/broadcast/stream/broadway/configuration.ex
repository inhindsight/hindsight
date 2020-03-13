defmodule Broadcast.Stream.Broadway.Configuration do
  use BroadwayConfigurator.OffBroadwayKafka
  use Properties, otp_app: :service_broadcast

  getter(:broadway_config, required: true)
  getter(:endpoints, required: true)

  def configure(_config, context) do
    unless Elsa.topic?(endpoints(), context.load.source) do
      Elsa.create_topic(endpoints(), context.load.source, create_opts(context))
    end

    super(broadway_config(), context)
  end

  def name(context) do
    :"broadcast_broadway_#{context.load.source}"
    |> Ok.ok()
  end

  def endpoints(_) do
    endpoints()
  end

  def connection(context) do
    :"broadcast_connection_#{context.load.source}"
  end

  def group(context) do
    "broadcast-#{context.load.source}"
  end

  def topics(context) do
    [context.load.source]
  end

  def offset_reset_policy(_) do
    :reset_to_latest
  end

  defp create_opts(context) do
    case get_in(context.load.config, ["kafka", "partitions"]) do
      nil -> []
      partitions -> [partitions: partitions]
    end
  end
end
